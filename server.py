import os
import subprocess
from flask import Flask, render_template, request, redirect, url_for, flash

# Pfad zur WireGuard-Konfiguration im Add-on
CONF_PATH = "/data/wg0.conf"

app = Flask(__name__)
app.secret_key = "change-this-secret"  # für Flash-Messages, egal was, wird eh nur lokal genutzt


def wg_interface_up() -> bool:
    """Prüfen, ob wg0 aktiv ist."""
    try:
        result = subprocess.run(
            ["wg", "show", "wg0"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        return result.returncode == 0
    except FileNotFoundError:
        return False


def restart_wireguard() -> bool:
    """WireGuard mit aktueller Config neu starten."""
    # wg0 herunterfahren (Fehler ignorieren, falls Interface nicht existiert)
    subprocess.run(["wg-quick", "down", "wg0"], check=False)

    if not os.path.exists(CONF_PATH):
        app.logger.warning("Keine wg0.conf gefunden, kann Tunnel nicht starten.")
        return False

    # Tunnel mit Config hochfahren
    result = subprocess.run(
        ["wg-quick", "up", CONF_PATH],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    if result.returncode != 0:
        app.logger.error("Fehler beim Starten von WireGuard:\nSTDOUT:\n%s\nSTDERR:\n%s",
                         result.stdout, result.stderr)
        return False

    app.logger.info("WireGuard wg0 erfolgreich gestartet.")
    return True


@app.route("/", methods=["GET"])
def index():
    config_exists = os.path.exists(CONF_PATH)
    tunnel_up = wg_interface_up()
    return render_template(
        "index.html",
        config_exists=config_exists,
        tunnel_up=tunnel_up,
        conf_path=CONF_PATH,
    )


@app.route("/upload", methods=["POST"])
def upload():
    if "configfile" not in request.files:
        flash("Keine Datei ausgewählt.", "error")
        return redirect(url_for("index"))

    file = request.files["configfile"]
    if file.filename == "":
        flash("Keine Datei ausgewählt.", "error")
        return redirect(url_for("index"))

    # Datei speichern
    os.makedirs(os.path.dirname(CONF_PATH), exist_ok=True)
    file.save(CONF_PATH)
    app.logger.info("Neue WireGuard-Konfiguration nach %s hochgeladen.", CONF_PATH)

    # Tunnel neu starten
    if restart_wireguard():
        flash("Konfiguration hochgeladen und Tunnel gestartet.", "success")
    else:
        flash("Konfiguration hochgeladen, aber Tunnel konnte nicht gestartet werden. Logs prüfen!", "error")

    return redirect(url_for("index"))


@app.route("/restart", methods=["POST"])
def restart():
    if not os.path.exists(CONF_PATH):
        flash("Keine Konfiguration gefunden. Bitte zuerst eine wg0.conf hochladen.", "error")
        return redirect(url_for("index"))

    if restart_wireguard():
        flash("Tunnel neu gestartet.", "success")
    else:
        flash("Tunnel konnte nicht neu gestartet werden. Logs prüfen!", "error")

    return redirect(url_for("index"))


if __name__ == "__main__":
    # Bei Start einmal prüfen, ob wg0 läuft, wenn Datei existiert,
    # (run.sh hat das aber eigentlich schon versucht)
    if os.path.exists(CONF_PATH) and not wg_interface_up():
        app.logger.info("wg0.conf vorhanden, aber Tunnel down. Versuche zu starten...")
        restart_wireguard()

    # Ingress: Home Assistant mapped selber auf die richtige URL,
    # wir lauschen einfach auf 0.0.0.0:8099
    app.run(host="0.0.0.0", port=8099)
