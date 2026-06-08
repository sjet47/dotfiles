#!/usr/bin/env python3
# 录屏范围指示边框：layer-shell 覆盖层,点击穿透,边框画在选区外圈
# 用法: recording-border.py X Y W H   (选区的 x y 宽 高)
# 窗口比选区四周各大 BW 像素,内孔正好等于录制区域 -> 边框不会进入录像
import sys
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, GtkLayerShell  # noqa: E402
import cairo  # noqa: E402

BW = 3                       # 边框宽度
COLOR = (0.92, 0.15, 0.15, 0.95)  # 红色

x, y, w, h = (int(a) for a in sys.argv[1:5])
area_w, area_h = w + 2 * BW, h + 2 * BW

win = Gtk.Window()
win.set_app_paintable(True)
visual = win.get_screen().get_rgba_visual()
if visual:
    win.set_visual(visual)
win.set_size_request(area_w, area_h)

GtkLayerShell.init_for_window(win)
GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.LEFT, True)
GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
GtkLayerShell.set_margin(win, GtkLayerShell.Edge.LEFT, x - BW)
GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, y - BW)
GtkLayerShell.set_exclusive_zone(win, -1)


def on_draw(_widget, cr):
    cr.set_operator(cairo.OPERATOR_SOURCE)
    cr.set_source_rgba(0, 0, 0, 0)
    cr.paint()  # 整窗清成透明
    cr.set_operator(cairo.OPERATOR_OVER)
    cr.set_source_rgba(*COLOR)
    cr.set_line_width(BW)
    # 居中描边,内边沿落在 BW 处,正好贴合录制区域边界
    cr.rectangle(BW / 2, BW / 2, area_w - BW, area_h - BW)
    cr.stroke()
    return False


def make_clickthrough(_widget):
    gdkwin = win.get_window()
    if gdkwin:
        gdkwin.input_shape_combine_region(cairo.Region())  # 空区域=全窗穿透


da = Gtk.DrawingArea()
da.connect("draw", on_draw)
win.add(da)
win.connect("realize", make_clickthrough)
win.show_all()
make_clickthrough(win)
Gtk.main()
