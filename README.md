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
7. Setze vor dem ersten Start sichere Datenbank-Passwörter in der Add-on-Konfiguration.
8. Starte das Add-on und öffne die Web UI.

## Externe MariaDB

Version `0.1.6` verwendet keine interne MariaDB mehr. Das Add-on verbindet sich mit einer bestehenden MariaDB.

Beispiel für das Home-Assistant-MariaDB-Add-on:

```yaml
db_host: core-mariadb
db_port: 3306
db_name: runalyze
db_user: runalyze
db_password: change_me
db_create: false
db_admin_user: root
db_admin_password: ""
```

Wenn Datenbank und Benutzer bereits existieren, `db_create: false` verwenden.

Wenn das Add-on Datenbank und Benutzer anlegen soll, `db_create: true` setzen und `db_admin_user` sowie `db_admin_password` mit einem MariaDB-Adminzugang befüllen.

Benötigte Rechte für den RUNALYZE-Benutzer:

```sql
CREATE DATABASE runalyze CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'runalyze'@'%' IDENTIFIED BY 'change_me';
GRANT ALL PRIVILEGES ON runalyze.* TO 'runalyze'@'%';
FLUSH PRIVILEGES;
```

## Update auf neue Version

Nach Änderungen im Repository:

1. Add-on stoppen.
2. In Home Assistant den Add-on-Store neu laden.
3. **RUNALYZE Server** auf Version `0.1.6` aktualisieren oder neu bauen.
4. Add-on starten.
5. Im Log auf diese Meldungen prüfen:

   `External MariaDB connection OK`

   `RUNALYZE web server is reachable on port 8099`

## Technische Änderungen

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
  rootfs/
    etc/apache2/sites-available/runalyze.conf
    tmp/patch-runalyze-composer.php
    usr/local/bin/run.sh
```
