"""Icone dell'app, identiche al programma per computer (tkiscrizioni.app.render_icon).
Uso (col Python del progetto per computer, che ha PySide6):
  C:\\dev\\build\\tk-iscrizioni\\.venv\\Scripts\\python.exe tools/genera_icona.py
Crea assets/icona.png (1024, completa) e assets/icona-adattiva.png (busta + bollino al centro, fondo trasparente)."""
import os
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
QUI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, r"C:\dev\build\tk-iscrizioni")

from PySide6.QtCore import QPointF, QRectF, Qt  # noqa: E402
from PySide6.QtGui import QColor, QImage, QPainter, QPainterPath, QPen  # noqa: E402
from PySide6.QtWidgets import QApplication  # noqa: E402

app = QApplication(sys.argv)
from tkiscrizioni.app import ACCENT_2, NAVY, render_icon  # noqa: E402

render_icon(1024).save(os.path.join(QUI, "assets", "icona.png"))

# adattiva: Android ritaglia un cerchio/ovale al centro (zona sicura ~66%), il fondo navy lo mette lui
size = 1024
img = QImage(size, size, QImage.Format.Format_ARGB32)
img.fill(Qt.GlobalColor.transparent)
p = QPainter(img)
p.setRenderHint(QPainter.RenderHint.Antialiasing)
p.translate(size * .19, size * .19)
s = size * .62
p.setPen(Qt.PenStyle.NoPen)
p.setBrush(QColor("#ffffff"))
p.drawRoundedRect(QRectF(s * .08, s * .2, s * .7, s * .5), s * .07, s * .07)
pen = QPen(QColor(NAVY), s * .05)
pen.setJoinStyle(Qt.PenJoinStyle.RoundJoin)
p.setPen(pen)
path = QPainterPath(QPointF(s * .13, s * .26))
path.lineTo(QPointF(s * .43, s * .48))
path.lineTo(QPointF(s * .73, s * .26))
p.drawPath(path)
p.setPen(Qt.PenStyle.NoPen)
p.setBrush(QColor(ACCENT_2))
p.drawEllipse(QPointF(s * .76, s * .74), s * .2, s * .2)
pen = QPen(QColor("#ffffff"), s * .06)
pen.setCapStyle(Qt.PenCapStyle.RoundCap)
pen.setJoinStyle(Qt.PenJoinStyle.RoundJoin)
p.setPen(pen)
path = QPainterPath(QPointF(s * .67, s * .74))
path.lineTo(QPointF(s * .74, s * .81))
path.lineTo(QPointF(s * .86, s * .67))
p.drawPath(path)
p.end()
img.save(os.path.join(QUI, "assets", "icona-adattiva.png"))
print("icone create")
