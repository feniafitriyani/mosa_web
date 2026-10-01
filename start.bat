@echo off
title MOSA Maps Web Server

cd /d "D:\MOSA\Aplikasi Web\mosa_maps_web\build\web"

python -m http.server 4000 --bind 127.0.0.1