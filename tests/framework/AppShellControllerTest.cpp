#include "presentation/controllers/AppShellController.h"

#include <QCoreApplication>
#include <QString>
#include <QtTest/QTest>

namespace todoit::presentation {

class AppShellControllerTest final : public QObject {
    Q_OBJECT

private slots:
    void exposesApplicationMetadata();
    void reportsReadyBackend();
};

void AppShellControllerTest::exposesApplicationMetadata() {
    const AppShellController controller;

    QCOMPARE(controller.applicationName(), QStringLiteral("To Do It"));
    QVERIFY(!controller.applicationVersion().isEmpty());
}

void AppShellControllerTest::reportsReadyBackend() {
    const AppShellController controller;

    QVERIFY(controller.backendReady());
}

}  // namespace todoit::presentation

QTEST_GUILESS_MAIN(todoit::presentation::AppShellControllerTest)

#include "AppShellControllerTest.moc"


