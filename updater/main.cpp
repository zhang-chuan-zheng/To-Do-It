#include "UpdateCoordinator.h"
#include "UpdateHistoryWriter.h"

#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QTextStream>

int main(int argc, char* argv[])
{
    QCoreApplication application(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("ToDoItMigrator"));

    QCommandLineParser parser;
    parser.setApplicationDescription(
        QStringLiteral("To Do It 离线安装与更新数据迁移器"));
    parser.addHelpOption();
    parser.addOption({QStringLiteral("data-dir"),
                      QStringLiteral("持久数据目录"),
                      QStringLiteral("path")});
    parser.addOption({QStringLiteral("manifest"),
                      QStringLiteral("当前发布清单"),
                      QStringLiteral("path")});
    parser.addOption({QStringLiteral("mode"),
                      QStringLiteral("install 或 update"),
                      QStringLiteral("mode"),
                      QStringLiteral("install")});
    parser.process(application);

    const auto dataDirectory = parser.value(QStringLiteral("data-dir")).trimmed();
    const auto manifestFile = parser.value(QStringLiteral("manifest")).trimmed();
    const auto mode = parser.value(QStringLiteral("mode")).trimmed().toLower();
    if (dataDirectory.isEmpty() || manifestFile.isEmpty()
        || (mode != QStringLiteral("install") && mode != QStringLiteral("update"))) {
        QTextStream(stderr) << QStringLiteral(
            "参数错误：必须提供 --data-dir、--manifest，--mode 只能是 install 或 update。\n");
        return 2;
    }

    const todoit::updater::UpdateCoordinator coordinator;
    const auto report = coordinator.execute({dataDirectory, manifestFile, mode});
    if (!report.success) {
        QString historyError;
        if (!todoit::updater::UpdateHistoryWriter::append(
                dataDirectory, report, &historyError)) {
            QTextStream(stderr) << historyError << '\n';
        }
    }
    QTextStream stream(report.success ? stdout : stderr);
    stream << report.message << '\n';
    if (!report.backupFile.isEmpty())
        stream << QStringLiteral("备份：") << report.backupFile << '\n';
    return report.success ? 0 : 3;
}
