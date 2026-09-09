#include "UpdateCoordinator.h"
#include "EventCsvMigrator.h"
#include "infrastructure/persistence/CsvCodec.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>
#include <QTest>

#include <sstream>
#include <string>
#include <vector>

namespace todoit::updater {
namespace {

constexpr auto kCurrentHeader =
    "\xEF\xBB\xBFschema_version,event_id,parent_id,sibling_order,title,importance,"
    "start_at,completed_at,status,note_html,attachments_json,created_at,updated_at\r\n";

bool writeBytes(const QString& path, const QByteArray& bytes)
{
    QFile file(path);
    return file.open(QIODevice::WriteOnly)
        && file.write(bytes) == bytes.size()
        && file.flush();
}

QString writeManifest(const QString& root)
{
    const auto path = QDir(root).filePath(QStringLiteral("release-manifest.json"));
    const QByteArray content = R"({
  "appVersion": "0.1.0",
  "eventSchema": 1,
  "settingsSchema": 1,
  "eventSchemas": [{
    "version": 1,
    "columns": [
      {"name":"schema_version","default":"1"},
      {"name":"event_id","default":""},
      {"name":"parent_id","default":""},
      {"name":"sibling_order","default":"0"},
      {"name":"title","default":""},
      {"name":"importance","default":"5"},
      {"name":"start_at","default":""},
      {"name":"completed_at","default":""},
      {"name":"status","default":""},
      {"name":"note_html","default":""},
      {"name":"attachments_json","default":"[]"},
      {"name":"created_at","default":""},
      {"name":"updated_at","default":""}
    ]
  }],
  "eventMigrations": []
})";
    return writeBytes(path, content) ? path : QString{};
}

} // namespace

class UpdateCoordinatorTest final : public QObject
{
    Q_OBJECT

private slots:
    void validatesAndBacksUpCurrentSchema();
    void refusesToGuessAnUnversionedSchema();
    void initializesWithoutCreatingEventData();
    void addsDefaultsAndDropsRemovedColumns();
    void refusesImplicitFieldRename();
};

void UpdateCoordinatorTest::validatesAndBacksUpCurrentSchema()
{
    QTemporaryDir temporary;
    QVERIFY(temporary.isValid());
    const auto dataDirectory = QDir(temporary.path()).filePath(QStringLiteral("data"));
    QVERIFY(QDir().mkpath(dataDirectory));
    const auto eventFile = QDir(dataDirectory).filePath(QStringLiteral("event.csv"));
    QVERIFY(writeBytes(eventFile, QByteArray(kCurrentHeader)));
    const auto before = QFile(eventFile).size();
    const auto manifest = writeManifest(temporary.path());
    QVERIFY(!manifest.isEmpty());

    const UpdateCoordinator coordinator;
    const auto report = coordinator.execute(
        {dataDirectory, manifest, QStringLiteral("update")});

    QVERIFY2(report.success, qPrintable(report.message));
    QCOMPARE(report.action, QStringLiteral("validated"));
    QCOMPARE(report.sourceSchema, 1);
    QCOMPARE(report.targetSchema, 1);
    QCOMPARE(QFile(eventFile).size(), before);
    QVERIFY(QFileInfo::exists(report.backupFile));
    QVERIFY(QFileInfo::exists(QDir(dataDirectory).filePath(
        QStringLiteral("config/install-state.json"))));
}

void UpdateCoordinatorTest::refusesToGuessAnUnversionedSchema()
{
    QTemporaryDir temporary;
    QVERIFY(temporary.isValid());
    const auto dataDirectory = QDir(temporary.path()).filePath(QStringLiteral("data"));
    QVERIFY(QDir().mkpath(dataDirectory));
    const auto eventFile = QDir(dataDirectory).filePath(QStringLiteral("event.csv"));
    const QByteArray source("\xEF\xBB\xBFtitle,status\r\nold task,doing\r\n");
    QVERIFY(writeBytes(eventFile, source));
    const auto manifest = writeManifest(temporary.path());
    QVERIFY(!manifest.isEmpty());

    const UpdateCoordinator coordinator;
    const auto report = coordinator.execute(
        {dataDirectory, manifest, QStringLiteral("update")});

    QVERIFY(!report.success);
    QCOMPARE(report.action, QStringLiteral("blocked"));
    QFile unchanged(eventFile);
    QVERIFY(unchanged.open(QIODevice::ReadOnly));
    QCOMPARE(unchanged.readAll(), source);
}

void UpdateCoordinatorTest::initializesWithoutCreatingEventData()
{
    QTemporaryDir temporary;
    QVERIFY(temporary.isValid());
    const auto dataDirectory = QDir(temporary.path()).filePath(QStringLiteral("data"));
    const auto manifest = writeManifest(temporary.path());
    QVERIFY(!manifest.isEmpty());

    const UpdateCoordinator coordinator;
    const auto report = coordinator.execute(
        {dataDirectory, manifest, QStringLiteral("install")});

    QVERIFY2(report.success, qPrintable(report.message));
    QCOMPARE(report.action, QStringLiteral("initialized"));
    QVERIFY(!QFileInfo::exists(QDir(dataDirectory).filePath(
        QStringLiteral("event.csv"))));
}

void UpdateCoordinatorTest::addsDefaultsAndDropsRemovedColumns()
{
    std::istringstream input(
        "\xEF\xBB\xBFschema_version,event_id,title,legacy_field\r\n"
        "1,abc,示例事项,discarded\r\n");
    const auto parsed = infrastructure::CsvCodec::parse(input);
    QVERIFY(!parsed.error.has_value());

    EventSchemaDescriptor target;
    target.version = 2;
    target.columns = {
        {QStringLiteral("schema_version"), QStringLiteral("2")},
        {QStringLiteral("event_id"), QString{}},
        {QStringLiteral("title"), QString{}},
        {QStringLiteral("category"), QStringLiteral("未分类")}};

    const auto migrated = EventCsvMigrator::migrate(parsed, target);
    QVERIFY2(migrated.success, qPrintable(migrated.error));
    std::istringstream migratedInput(migrated.content.toStdString());
    const auto migratedCsv = infrastructure::CsvCodec::parse(migratedInput);
    QVERIFY(!migratedCsv.error.has_value());
    QCOMPARE(migratedCsv.records.size(), std::size_t{2});
    QVERIFY(migratedCsv.records[0].fields
            == (std::vector<std::string>{"schema_version", "event_id", "title", "category"}));
    QVERIFY(migratedCsv.records[1].fields
            == (std::vector<std::string>{"2", "abc", "示例事项", "未分类"}));
}

void UpdateCoordinatorTest::refusesImplicitFieldRename()
{
    QTemporaryDir temporary;
    QVERIFY(temporary.isValid());
    const auto manifestPath = QDir(temporary.path()).filePath(
        QStringLiteral("release-manifest.json"));
    const QByteArray content = R"({
  "appVersion": "0.2.0",
  "eventSchema": 2,
  "settingsSchema": 1,
  "eventSchemas": [
    {"version":1,"columns":[
      {"name":"schema_version","default":"1"},
      {"name":"event_id","default":""},
      {"name":"title","default":""}
    ]},
    {"version":2,"columns":[
      {"name":"schema_version","default":"2"},
      {"name":"event_id","default":""},
      {"name":"renamed_title","default":""}
    ]}
  ],
  "eventMigrations": [{
    "id":"event-v1-to-v2",
    "fromSchema":1,
    "toSchema":2,
    "removedFields":[]
  }]
})";
    QVERIFY(writeBytes(manifestPath, content));

    QString error;
    const auto manifest = UpdateManifest::load(manifestPath, &error);
    QVERIFY(!manifest.has_value());
    QVERIFY2(error.contains(QStringLiteral("可能发生了字段重命名")),
             qPrintable(error));
}

} // namespace todoit::updater

QTEST_GUILESS_MAIN(todoit::updater::UpdateCoordinatorTest)

#include "UpdateCoordinatorTest.moc"
