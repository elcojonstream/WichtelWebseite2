# WichtelWebseite2
Another Wichtelwebseite from GPT

# 🎄 Familien-Wichteln

Weihnachtliche Familien-Wichtel-Seite mit Anmeldung, Wunschlisten, persönlichen Geheimlinks, Geschenk-Animation, Musik und Admin-Dashboard.

## Architektur / warum nicht nur GitHub Pages?
GitHub Pages kann nur statische Dateien ausliefern. Für geheime persönliche Zuordnungen und einen Adminbereich braucht es eine geschützte Serverkomponente. Dieses Projekt nutzt **GitHub als Quellcode**, **Cloudflare Pages als Hosting** und **Supabase als Datenbank + serverseitige API**. Alle drei bieten kostenlose Einstiegspläne; die Anbieter können Limits und Preise ändern.

## 1) Supabase einrichten
1. Auf https://supabase.com ein Projekt erstellen.
2. Unter **SQL Editor → New query** den kompletten Inhalt von `supabase/schema.sql` ausführen.
3. Unter **Project Settings → API** Project URL und `anon/public` Key kopieren.
4. In `app.js` die Platzhalter `SUPABASE_URL` und `SUPABASE_ANON_KEY` ersetzen. Der anon-Key darf im Browser liegen; **niemals** den `service_role`-Key dort eintragen oder in GitHub committen.

## 2) Edge Function veröffentlichen
Supabase CLI und Node.js installieren, dann im Projektordner:

```bash
npm install -g supabase
supabase login
supabase link --project-ref DEIN_PROJECT_REF
supabase secrets set WICHTEL_ADMIN_PASSWORD='DEIN-LANGES-EINZIGARTIGES-PASSWORT'
supabase secrets set WICHTEL_SIGNING_SECRET='EIN-LANGER-ZUFAELLIGER-WERT-MIT-MINDESTENS-32-ZEICHEN'
supabase functions deploy wichtel-api --no-verify-jwt
```

`DEIN_PROJECT_REF` findest du in Supabase unter **Project Settings → General**. `--no-verify-jwt` ist erforderlich, weil Familienmitglieder ohne Supabase-Account über ihren persönlichen Token-Link zugreifen. Die Funktion prüft Admin-Rechte selbst.

## 3) Lokal testen
Im Projektordner einen lokalen Webserver starten:

```bash
python3 -m http.server 8080
```

Dann http://localhost:8080 öffnen. Zuerst mit zwei oder drei Testnamen testen.

## 4) GitHub-Repository erstellen
1. Auf https://github.com ein Repository `familien-wichteln` erstellen.
2. Für die automatische Cloudflare-Anbindung kann das Repository öffentlich sein. Es enthält keine Datenbankdaten oder geheimen Schlüssel. Wenn du ein privates Repository möchtest, prüfe die GitHub-/Cloudflare-Kontoeinstellungen für private Repositories.
3. Im Projektordner:

```bash
git init
git add .
git commit -m "Erste Version der Weihnachts-Wichtel-Webseite"
git branch -M main
git remote add origin https://github.com/DEIN-GITHUB-NAME/familien-wichteln.git
git push -u origin main
```

## 5) Cloudflare Pages veröffentlichen
1. Bei https://pages.cloudflare.com anmelden.
2. **Create a project → Connect to Git** auswählen und GitHub verbinden.
3. Repository `familien-wichteln` auswählen.
4. Framework preset: **None**; Build command leer lassen; Build output directory: `/`.
5. Deployment starten. Cloudflare stellt eine Adresse wie `https://familien-wichteln.pages.dev` bereit.
6. Bei jedem Push auf `main` wird die Seite automatisch neu veröffentlicht.

## 6) Ablauf für die Familie
1. Familie öffnet die öffentliche Webseite und meldet sich mit Name und Wunschliste an.
2. Nach erfolgreicher Anmeldung wird ein persönlicher Link angezeigt. Die Person muss diesen Link speichern oder selbst an sich schicken.
3. Admin öffnet unten/oben den Adminbereich und meldet sich mit dem eingerichteten Admin-Passwort an.
4. Admin prüft Teilnehmer und Wunschlisten und startet die Ziehung.
5. Jeder öffnet seinen persönlichen Link und klickt auf das Geschenk.

## Wichtige Sicherheitshinweise und Grenzen
- Öffentliche Liste zeigt nur Namen. Zuordnungen werden ausschließlich über die geschützte Edge Function abgefragt.
- Der Teilnehmer-Token ist ein Geheimnis: Wer den Link besitzt, kann die Zuordnung sehen. Nicht in einen Gruppenchat stellen.
- In der Datenbank wird nur der SHA-256-Hash des Tokens gespeichert. Daher kann der Admin verlorene Links nicht auslesen oder erneut anzeigen. Teilnehmer sollten den Link nach der Anmeldung sichern. Ein späterer Ausbau kann eine sichere Link-Neuausstellung ergänzen.
- Admin-Zuordnungen sind nur nach Admin-Login sichtbar. Admin-Sitzungstoken laufen nach acht Stunden ab.
- Ziehung wird serverseitig vollständig validiert: mindestens zwei Teilnehmende, keine Selbstziehung, jeder Empfänger genau einmal, alle Teilnehmenden genau einmal als Schenkende.
- Eine Ziehung kann nur einmal erfolgen, bis Admin ausdrücklich zurücksetzt.
- Vor der echten Runde unbedingt mit Testdaten prüfen und danach Testteilnehmer löschen (Supabase Table Editor). Nicht versehentlich echte Teilnehmende löschen.
- Für einen größeren öffentlichen Einsatz sollten zusätzlich Rate-Limits gegen automatisierte Anmeldungen/Passwortversuche und ein Verfahren zur Admin-Passwortrotation ergänzt werden.
- Musik ist eine einfache eigens erzeugte Tonfolge und startet erst nach Klick (Browser-Autoplay-Regeln).
