# RUNALYZE Home Assistant Add-on Repository

Dieses Repository enthält ein Home-Assistant-Add-on für einen lokalen RUNALYZE-Server.

## Installation über Home Assistant

1. Öffne Home Assistant.
2. Gehe zu **Einstellungen → Add-ons → Add-on Store**.
3. Öffne oben rechts **⋮ → Repositories**.
4. Füge dieses Repository hinzu:

   `https://github.com/binbashmedium/runalyze-ha-addon`

5. Lade den Add-on-Store neu.
6. Installiere **RUNALYZE Server**.
7. Starte das Add-on und öffne die Web UI.

## RUNALYZE-Quelle

Ab Version `0.1.12` wird RUNALYZE aus diesem Fork gebaut:

```text
https://github.com/codeproducer198/Runalyze.git
```

Verwendeter Branch:

```text
master
```

## Manuelle MariaDB-Konfiguration

Empfohlen, wenn du einen eigenen Datenbankbenutzer angelegt hast:

```yaml
db_use_supervisor_service: false
db_host: core-mariadb
db_port: 3306
db_name: runalyze
db_user: runalyze
db_password: change_me
db_create: false
```

`db_create: false` verwenden, wenn die Datenbank bereits existiert.

## MariaDB über Home Assistant Supervisor

Optional kann der MySQL-Service beim Home-Assistant-Supervisor angefordert werden:

```yaml
hassio_api: true
services:
  - mysql:need
```

Dafür muss gesetzt sein:

```yaml
db_use_supervisor_service: true
```

Dann überschreibt der Supervisor Host, Port, Benutzer und Passwort. Das ist nicht geeignet, wenn ein manuell angelegter Benutzer verwendet werden soll.

## Update auf neue Version

Nach Änderungen im Repository:

1. Add-on stoppen.
2. In Home Assistant den Add-on-Store neu laden.
3. **RUNALYZE Server** auf Version `0.1.12` aktualisieren oder neu bauen.
4. Add-on starten.
5. Im Log auf diese Meldungen prüfen:

   `Using configured database user ...`

   `External MariaDB connection OK`

   `RUNALYZE web server is reachable on port 8099`

## Technische Änderungen

Version `0.1.12` stellt die RUNALYZE-Quelle auf `https://github.com/codeproducer198/Runalyze.git`, Branch `master`, um und entfernt die bisherige Upstream-Patch-Installation aus dem Dockerfile.

Version `0.1.11` ergänzt detailliertes HTTP-500-Logging für die RUNALYZE-Fehlerseite.

Version `0.1.10` installiert die PHP-Erweiterung `gettext`.

Version `0.1.9` verwendet manuelle DB-Zugangsdaten standardmäßig vor Supervisor-Zugangsdaten.

Version `0.1.8` ergänzt `hassio_api: true`, `services: mysql:need` und liest die MySQL-Zugangsdaten über den Supervisor-Service-Endpunkt.

Version `0.1.7` entfernt die Root/Admin-Datenbankoptionen. `db_create` verwendet den konfigurierten `db_user`. Zusätzlich wurde ein Add-on-Icon unter `runalyze/icon.svg` hinzugefügt.

Version `0.1.6` entfernt den internen MariaDB-Server aus dem Container und schreibt RUNALYZE `data/config.yml` anhand der Add-on-Datenbankoptionen.

## Repository-Struktur

```text
repository.yaml
runalyze/
  config.yaml
  Dockerfile
  icon.svg
  rootfs/
    etc/apache2/sites-available/runalyze.conf
    tmp/patch-runalyze-composer.php
    usr/local/bin/run.sh
```
