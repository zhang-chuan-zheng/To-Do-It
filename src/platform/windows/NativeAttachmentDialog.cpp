#include "platform/windows/NativeAttachmentDialog.h"

#include <QUrl>
#include <QVariantMap>

#include <utility>

#ifdef Q_OS_WIN
#  ifndef NOMINMAX
#    define NOMINMAX
#  endif
#  include <Windows.h>
#  include <ShObjIdl.h>
#  include <wrl/client.h>

#  include <atomic>
#endif

namespace todoit::platform::windows {
namespace {

#ifdef Q_OS_WIN

using Microsoft::WRL::ComPtr;

constexpr DWORD addCurrentFolderButtonId = 0x54444901;

class ComApartment final
{
public:
    ComApartment()
        : result_(CoInitializeEx(nullptr,
              COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE))
        , ownsInitialization_(SUCCEEDED(result_))
    {
    }

    ~ComApartment()
    {
        if (ownsInitialization_) {
            CoUninitialize();
        }
    }

    [[nodiscard]] bool isReady() const noexcept
    {
        return SUCCEEDED(result_) || result_ == RPC_E_CHANGED_MODE;
    }

    [[nodiscard]] HRESULT result() const noexcept
    {
        return result_;
    }

private:
    HRESULT result_;
    bool ownsInitialization_;
};

[[nodiscard]] QString nativeErrorMessage(const QString& operation, HRESULT result)
{
    return QStringLiteral("%1失败（HRESULT 0x%2）")
        .arg(operation,
            QString::number(static_cast<quint32>(result), 16).rightJustified(8, u'0'));
}

[[nodiscard]] QString fileSystemPath(IShellItem* item)
{
    if (item == nullptr) {
        return {};
    }

    PWSTR rawPath = nullptr;
    const auto result = item->GetDisplayName(SIGDN_FILESYSPATH, &rawPath);
    if (FAILED(result) || rawPath == nullptr) {
        return {};
    }

    const auto path = QString::fromWCharArray(rawPath);
    CoTaskMemFree(rawPath);
    return path;
}

class NativeFileDialogEvents final
    : public IFileDialogEvents
    , public IFileDialogControlEvents
{
public:
    explicit NativeFileDialogEvents(IFileDialog* dialog)
        : dialog_(dialog)
    {
    }

    NativeFileDialogEvents(const NativeFileDialogEvents&) = delete;
    NativeFileDialogEvents& operator=(const NativeFileDialogEvents&) = delete;

    [[nodiscard]] QString selectedFolder() const
    {
        return selectedFolder_;
    }

    IFACEMETHODIMP QueryInterface(REFIID interfaceId, void** object) override
    {
        if (object == nullptr) {
            return E_POINTER;
        }

        *object = nullptr;
        if (interfaceId == __uuidof(IUnknown)
            || interfaceId == __uuidof(IFileDialogEvents)) {
            *object = static_cast<IFileDialogEvents*>(this);
        } else if (interfaceId == __uuidof(IFileDialogControlEvents)) {
            *object = static_cast<IFileDialogControlEvents*>(this);
        } else {
            return E_NOINTERFACE;
        }

        AddRef();
        return S_OK;
    }

    IFACEMETHODIMP_(ULONG) AddRef() override
    {
        return ++referenceCount_;
    }

    IFACEMETHODIMP_(ULONG) Release() override
    {
        return --referenceCount_;
    }

    IFACEMETHODIMP OnFileOk(IFileDialog*) override { return S_OK; }
    IFACEMETHODIMP OnFolderChanging(IFileDialog*, IShellItem*) override { return S_OK; }
    IFACEMETHODIMP OnFolderChange(IFileDialog*) override { return S_OK; }
    IFACEMETHODIMP OnSelectionChange(IFileDialog*) override { return S_OK; }
    IFACEMETHODIMP OnTypeChange(IFileDialog*) override { return S_OK; }

    IFACEMETHODIMP OnShareViolation(
        IFileDialog*, IShellItem*, FDE_SHAREVIOLATION_RESPONSE* response) override
    {
        if (response != nullptr) {
            *response = FDESVR_DEFAULT;
        }
        return S_OK;
    }

    IFACEMETHODIMP OnOverwrite(
        IFileDialog*, IShellItem*, FDE_OVERWRITE_RESPONSE* response) override
    {
        if (response != nullptr) {
            *response = FDEOR_DEFAULT;
        }
        return S_OK;
    }

    IFACEMETHODIMP OnItemSelected(IFileDialogCustomize*, DWORD, DWORD) override
    {
        return S_OK;
    }

    IFACEMETHODIMP OnButtonClicked(IFileDialogCustomize*, DWORD controlId) override
    {
        if (controlId != addCurrentFolderButtonId || dialog_ == nullptr) {
            return S_OK;
        }

        ComPtr<IShellItem> currentFolder;
        if (FAILED(dialog_->GetFolder(&currentFolder))) {
            return S_OK;
        }

        const auto folderPath = fileSystemPath(currentFolder.Get());
        if (folderPath.isEmpty()) {
            return S_OK;
        }

        selectedFolder_ = folderPath;
        return dialog_->Close(S_OK);
    }

    IFACEMETHODIMP OnCheckButtonToggled(
        IFileDialogCustomize*, DWORD, BOOL) override
    {
        return S_OK;
    }

    IFACEMETHODIMP OnControlActivating(IFileDialogCustomize*, DWORD) override
    {
        return S_OK;
    }

private:
    std::atomic<ULONG> referenceCount_ { 1 };
    IFileDialog* dialog_ = nullptr;
    QString selectedFolder_;
};

[[nodiscard]] QVariantMap attachmentEntry(const QString& path, bool isFolder)
{
    return {
        { QStringLiteral("url"), QUrl::fromLocalFile(path).toString() },
        { QStringLiteral("isFolder"), isFolder }
    };
}

#endif

} // namespace

NativeAttachmentDialog::NativeAttachmentDialog(QObject* parent)
    : QObject(parent)
{
}

QString NativeAttachmentDialog::lastError() const
{
    return lastError_;
}

QVariantList NativeAttachmentDialog::chooseAttachments()
{
    setLastError({});

#ifdef Q_OS_WIN
    const ComApartment apartment;
    if (!apartment.isReady()) {
        setLastError(nativeErrorMessage(QStringLiteral("初始化 Windows 文件选择器"),
            apartment.result()));
        return {};
    }

    ComPtr<IFileOpenDialog> dialog;
    auto result = CoCreateInstance(CLSID_FileOpenDialog, nullptr,
        CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dialog));
    if (FAILED(result)) {
        setLastError(nativeErrorMessage(QStringLiteral("创建 Windows 文件选择器"), result));
        return {};
    }

    FILEOPENDIALOGOPTIONS options = {};
    result = dialog->GetOptions(&options);
    if (SUCCEEDED(result)) {
        options |= FOS_FORCEFILESYSTEM | FOS_FILEMUSTEXIST | FOS_PATHMUSTEXIST
            | FOS_ALLOWMULTISELECT | FOS_DONTADDTORECENT;
        result = dialog->SetOptions(options);
    }
    if (FAILED(result)) {
        setLastError(nativeErrorMessage(QStringLiteral("配置 Windows 文件选择器"), result));
        return {};
    }

    dialog->SetTitle(L"添加附件");
    dialog->SetOkButtonLabel(L"添加所选文件");

    ComPtr<IFileDialogCustomize> customization;
    result = dialog.As(&customization);
    if (SUCCEEDED(result)) {
        result = customization->AddPushButton(
            addCurrentFolderButtonId, L"添加当前文件夹");
    }
    if (FAILED(result)) {
        setLastError(nativeErrorMessage(QStringLiteral("配置文件夹添加按钮"), result));
        return {};
    }

    NativeFileDialogEvents dialogEvents(dialog.Get());
    DWORD eventCookie = 0;
    result = dialog->Advise(&dialogEvents, &eventCookie);
    if (FAILED(result)) {
        setLastError(nativeErrorMessage(QStringLiteral("连接 Windows 文件选择器"), result));
        return {};
    }

    result = dialog->Show(GetActiveWindow());
    dialog->Unadvise(eventCookie);

    if (result == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        return {};
    }
    if (FAILED(result)) {
        setLastError(nativeErrorMessage(QStringLiteral("打开 Windows 文件选择器"), result));
        return {};
    }

    const auto selectedFolder = dialogEvents.selectedFolder();
    if (!selectedFolder.isEmpty()) {
        return { attachmentEntry(selectedFolder, true) };
    }

    ComPtr<IShellItemArray> selectedItems;
    result = dialog->GetResults(&selectedItems);
    if (FAILED(result)) {
        setLastError(nativeErrorMessage(QStringLiteral("读取所选附件"), result));
        return {};
    }

    DWORD itemCount = 0;
    result = selectedItems->GetCount(&itemCount);
    if (FAILED(result)) {
        setLastError(nativeErrorMessage(QStringLiteral("统计所选附件"), result));
        return {};
    }

    QVariantList entries;
    entries.reserve(static_cast<qsizetype>(itemCount));
    for (DWORD index = 0; index < itemCount; ++index) {
        ComPtr<IShellItem> item;
        if (FAILED(selectedItems->GetItemAt(index, &item))) {
            continue;
        }
        const auto path = fileSystemPath(item.Get());
        if (!path.isEmpty()) {
            entries.push_back(attachmentEntry(path, false));
        }
    }
    return entries;
#else
    setLastError(QStringLiteral("当前平台不支持 Windows 原生附件选择器"));
    return {};
#endif
}

void NativeAttachmentDialog::setLastError(QString message)
{
    if (lastError_ == message) {
        return;
    }
    lastError_ = std::move(message);
    emit lastErrorChanged();
}

} // namespace todoit::platform::windows
