#include <QGuiApplication>
#include <QFile>
#include <QQmlApplicationEngine>
#include <QQmlError>
#include <QTextStream>
#include <QUrl>
#include <QtQml/qqml.h>

#include "infrastructure/path/InstallPaths.h"
#include "infrastructure/persistence/CsvEventRepository.h"
#include "presentation/controllers/AppShellController.h"
#include "presentation/controllers/EventDataController.h"
#include "presentation/controllers/RichTextFormatter.h"

#include <cstdlib>
#include <filesystem>
#include <utility>

int main(int argc, char* argv[])
{
    QGuiApplication application(argc, argv);
    todoit::presentation::AppShellController appShellController;
    application.setApplicationName(appShellController.applicationName());
    application.setApplicationVersion(appShellController.applicationVersion());
    application.setOrganizationName(QStringLiteral("ToDoIt"));

    const auto executableDirectory = std::filesystem::path(
        QCoreApplication::applicationDirPath().toStdWString());
    const auto installPaths = todoit::infrastructure::InstallPaths::fromExecutableDirectory(
        executableDirectory);
    const auto eventFileOverride = qEnvironmentVariable("TODOIT_EVENT_FILE");
    const auto eventFile = eventFileOverride.isEmpty()
        ? installPaths.eventFile()
        : std::filesystem::path(eventFileOverride.toStdWString());
    const todoit::infrastructure::CsvEventRepository eventRepository(eventFile);
    todoit::presentation::EventDataController eventDataController(
        eventRepository, eventRepository.load(), eventFile);
    todoit::presentation::RichTextFormatter richTextFormatter;

    qmlRegisterSingletonInstance(
        "ToDoIt.Controllers", 1, 0, "AppShell", &appShellController);
    qmlRegisterSingletonInstance(
        "ToDoIt.Controllers", 1, 0, "EventData", &eventDataController);
    qmlRegisterSingletonInstance(
        "ToDoIt.Controllers", 1, 0, "RichTextFormatter", &richTextFormatter);

    QQmlApplicationEngine engine;
    QList<QQmlError> startupWarnings;
    QObject::connect(&engine, &QQmlEngine::warnings, &engine,
        [&startupWarnings](const QList<QQmlError>& warnings) {
            startupWarnings.append(warnings);
        });

    const QUrl mainQmlUrl(QStringLiteral("qrc:/qt/qml/ToDoIt/Main.qml"));
    engine.load(mainQmlUrl);

    if (engine.rootObjects().isEmpty()) {
        const auto logPath = QCoreApplication::applicationDirPath()
            + QStringLiteral("/startup-error.log");
        QFile logFile(logPath);
        if (logFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream stream(&logFile);
            stream << "To Do It failed to create the root QML object.\n";
            stream << "Entry URL: " << mainQmlUrl.toString() << '\n';
            if (startupWarnings.isEmpty()) {
                stream << "QQmlApplicationEngine did not report a detailed warning.\n";
            } else {
                stream << "QML diagnostics:\n";
                for (const auto& warning : std::as_const(startupWarnings)) {
                    stream << warning.toString() << '\n';
                }
            }
        }
        return EXIT_FAILURE;
    }

    return application.exec();
}
