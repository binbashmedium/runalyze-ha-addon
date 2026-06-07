# RUNALYZE Home Assistant Add-on Repository

Dieses Repository enthält ein Home-Assistant-Add-on für einen lokalen RUNALYZE Open-Source-Server.

## Installation über Home Assistant

1. Öffne Home Assistant.
2. Gehe zu **Einstellungen → Add-ons → Add-on Store**.
3. Öffne oben rechts **⋮ → Repositories**.
4. Füge dieses Repository hinzu:

   `https://github.com/binbashmedium/runalyze-ha-addon`

5. Lade den Add-on-Store neu.
6. Installiere **RUNALYZE Server**.
7. Starte das Add-on und öffne die Web UI.

## MariaDB über Home Assistant Supervisor

Version `0.1.8` fordert den MySQL-Service beim Home-Assistant-Supervisor an:

```yaml
hassio_api: true
services:
  - mysql:need
```

Dadurch holt das Add-on Host, Port, Benutzer und Passwort automatisch vom Supervisor, so wie andere Add-ons mit MariaDB-Servicebindung. Die Add-on-Optionen dienen als Fallback oder zur Auswahl der Datenbank.

Empfohlene Konfiguration:

```yaml
db_use_supervisor_service: true
db_host: core-mariadb
db_port: 3306
db_name: runalyze
db_user: service
db_password: ""
db_create: false
```

Wenn `db_use_supervisor_service: true` gesetzt ist, kann `db_password` leer bleiben. Das Passwort kommt dann vom Supervisor-Service.

## Manuelle MariaDB-Konfiguration

Nur verwenden, wenn keine Supervisor-Servicebindung genutzt werden soll:

```yaml
db_use_supervisor_service: false
db_host: core-mariadb
db_port: 3306
db_name: runalyze
db_user: service
db_password: change_me
db_create: false
```

## Update auf neue Version

Nach Änderungen im Repository:

1. Add-on stoppen.
2. In Home Assistant den Add-on-Store neu laden.
3. **RUNALYZE Server** auf Version `0.1.8` aktualisieren oder neu bauen.
4. Add-on starten.
5. Im Log auf diese Meldungen prüfen:

   `Reading MySQL service credentials from Home Assistant Supervisor`

   `Using Supervisor MySQL service user ...`

   `External MariaDB connection OK`

   `RUNALYZE web server is reachable on port 8099`

## Technische Änderungen

Version `0.1.8` ergänzt `hassio_api: true`, `services: mysql:need` und liest die MySQL-Zugangsdaten über den Supervisor-Service-Endpunkt. Damit muss das MariaDB-Servicepasswort nicht mehr manuell eingetragen werden.

Version `0.1.7` entfernt die Root/Admin-Datenbankoptionen. `db_create` verwendet den konfigurierten `db_user`. Zusätzlich wurde ein Add-on-Icon unter `runalyze/icon.svg` hinzugefügt.

Version `0.1.6` entfernt den internen MariaDB-Server aus dem Container und schreibt RUNALYZE `data/config.yml` anhand der Add-on-Datenbankoptionen.

Version `0.1.5` verwendet Composer 2 mit normalisierten Legacy-Paketnamen und PicoFeed-Patch.

Version `0.1.4` ersetzt das nicht mehr abrufbare `miniflux/picofeed` durch einen kompatiblen Fork.

Version `0.1.2` ergänzt `libonig-dev`, damit die PHP-Erweiterung `mbstring` erfolgreich gebaut werden kann.

Version `0.1.1` verwendet PHP 7.4 statt Debian Bookworm PHP, installiert Composer-Abhängigkeiten beim Image-Build, setzt Apache explizit auf Port `8099`, richtet `ingress_port: 8099` ein und schreibt PHP/Apache-Fehler direkt ins Add-on-Log.

## Hinweis zur RUNALYZE-Version

Das Add-on verwendet die archivierte Open-Source-Version aus dem Branch `support/4.3.x` des RUNALYZE-Projekts. Der heutige RUNALYZE-Dienst ist nicht identisch mit dieser archivierten Self-hosted-Version.

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
