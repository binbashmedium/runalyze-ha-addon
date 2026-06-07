# RUNALYZE Server Add-on

Dieses Add-on startet einen lokalen RUNALYZE Open-Source-Server in Home Assistant.

## Konfiguration

Vor dem ersten Start sollten die Standardpasswörter geändert werden.

```yaml
db_name: runalyze
db_user: runalyze
db_password: change_me
db_root_password: change_me_root
```

## Erstinstallation

1. Add-on installieren.
2. Passwörter in der Add-on-Konfiguration setzen.
3. Add-on starten.
4. Web UI öffnen.
5. Falls der RUNALYZE-Installer angezeigt wird, folgende Datenbankdaten verwenden:

| Feld | Wert |
|---|---|
| Host | `127.0.0.1` |
| Port | `3306` |
| Datenbank | Wert aus `db_name` |
| Benutzer | Wert aus `db_user` |
| Passwort | Wert aus `db_password` |

## Version 0.1.1

Diese Version behebt die weiße Ingress-Seite durch folgende Änderungen:

- Apache hört explizit auf Port `8099`.
- `ingress_port` ist auf `8099` gesetzt.
- PHP 7.4 wird verwendet, passend zur archivierten RUNALYZE-Codebasis.
- Composer-Abhängigkeiten werden im Image installiert.
- Apache- und PHP-Fehler erscheinen direkt im Add-on-Log.
- Beim Start wird `http://127.0.0.1:8099/` geprüft.

## Persistenz

MariaDB-Daten werden unter `/data/mysql` gespeichert und über Home-Assistant-Add-on-Backups gesichert.

## Einschränkung

RUNALYZE Open Source ist archiviert. Dieses Add-on stellt die letzte archivierte Self-hosted-Variante bereit, nicht die aktuelle RUNALYZE-Cloud.
