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

## Update auf neue Version

Nach Änderungen im Repository:

1. Add-on stoppen.
2. In Home Assistant den Add-on-Store neu laden.
3. **RUNALYZE Server** auf Version `0.1.3` aktualisieren oder neu bauen.
4. Add-on starten.
5. Im Log auf diese Meldung prüfen:

   `RUNALYZE web server is reachable on port 8099`

## Datenbankdaten

Das Add-on startet MariaDB im selben Container und legt die Daten unter `/data/mysql` ab. Home Assistant sichert `/data` im Add-on-Backup.

Die verwendeten Datenbankdaten stehen nach dem Start zusätzlich in `/data/database.txt` im Add-on-Container.

Standardwerte:

| Feld | Wert |
|---|---|
| Host | `127.0.0.1` |
| Port | `3306` |
| Datenbank | `runalyze` |
| Benutzer | `runalyze` |

## Technische Änderungen

Version `0.1.3` verwendet Composer `1.10`, weil Composer 2 alte Paketnamen mit Großbuchstaben im archivierten RUNALYZE-Branch ablehnt.

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
    usr/local/bin/run.sh
```
