# FFmpeg Minimal Audio Builder for LosslessRobot

Сборщик ультра-минималистичного FFmpeg бинарника (размером **~3-5 МБ** вместо стандартных ~80-100 МБ), оптимизированного специально для десктопного приложения [LosslessRobot](https://github.com/yarchefis).

Поддерживает полностью автоматизированную и ручную кросс-платформенную сборку под **Windows (`x86_64`)**, **Linux (`x86_64`, `arm64`)** и **macOS (`Universal Binary` / `Apple Silicon arm64` / `Intel x86_64`)** через GitHub Actions.

---

## 🎯 Назначение и поддерживаемые сценарии

Бинарник содержит только необходимые аудио-кодеки, муксеры, демуксеры и фильтры:

| Сценарий | Вход | Выход | Команда FFmpeg |
|---|---|---|---|
| **1. Dolby Atmos -> 5.1/7.1 FLAC** | `.mp4` (E-AC-3 JOC 5.1/7.1) | `.flac` (24-bit 48kHz, s32) | `ffmpeg -y -i in.mp4 -vn -c:a flac -sample_fmt s32 out.flac` |
| **2. Atmos Remux (Keep)** | `.mp4` (E-AC-3 JOC) | `.m4a` (чистый E-AC-3) | `ffmpeg -y -i in.mp4 -vn -c:a copy -f mp4 out.m4a` |
| **3. AAC -> MP3 320k** | `.m4a` / `.aac` (AAC LC) | `.mp3` (320 kbps) | `ffmpeg -y -i in.m4a -vn -c:a libmp3lame -b:a 320k out.mp3` |
| **4. Raw Remux** | `.mp4` (FLAC/MP3 внутри MP4/DASH) | `.flac` / `.mp3` | `ffmpeg -y -i in.mp4 -vn -c:a copy out.flac` |
| **5. ALAC / Opus / Vorbis decode** | `.m4a` (ALAC) / `.ogg` (Opus) | `.wav` / `.flac` | `ffmpeg -y -i in.m4a -c:a flac out.flac` |

---

## 📦 Включенные компоненты

* **Демуксеры (Demuxers)**: `mov` (ISO-BMFF: `.mp4`, `.m4a`, `DASH chunks`), `flac`, `mp3`, `aac`, `ogg`, `wav`, `eac3`, `ac3`
* **Муксеры (Muxers)**: `flac`, `mp4` (поддержка `.m4a` с E-AC-3), `mp3`, `wav`, `ogg`, `adts`
* **Декодеры (Decoders)**: `eac3` (Dolby Digital Plus / Atmos JOC), `ac3`, `aac`, `aac_latm`, `flac`, `mp3`, `mp3float`, `alac`, `opus`, `vorbis`, `pcm_s16le`, `pcm_s24le`, `pcm_s32le`, `pcm_f32le`
* **Энкодеры (Encoders)**: `flac` (24-bit s32), `libmp3lame` (MP3 320k CBR/VBR), `pcm_s16le`, `pcm_s24le`
* **Парсеры (Parsers)**: `aac`, `aac_latm`, `ac3`, `flac`, `mpegaudio`, `vorbis`, `opus`
* **Фильтры**: `aresample`, `aformat`, `anull`, `libswresample`
* **Протоколы**: `file`, `pipe`

---

## 🚀 Запуск сборки в GitHub Actions

Вы можете запускать сборку как для всех платформ сразу, так и для каждой по отдельности:

1. Перейдите во вкладку **Actions** в GitHub репозитории: `https://github.com/yarchefis/ffmpeg-builder/actions`.
2. Выберите воркфлоу **Build Minimal FFmpeg**.
3. Нажмите **Run workflow** справа вверху.
4. Выберите параметры:
   - **Target Platform**:
     - `all` — собрать параллельно под все ОС (Windows, Linux x86_64/arm64, macOS Universal)
     - `windows-x86_64` — только Windows x86_64 (`ffmpeg.exe`)
     - `linux-x86_64` — только Linux x86_64 (статический binary)
     - `linux-arm64` — только Linux ARM64
     - `macos-universal` — универсальный бинарник под Intel + Apple Silicon M1/M2/M3/M4
     - `macos-arm64` — только Apple Silicon
     - `macos-x86_64` — только macOS Intel
   - **FFmpeg version**: версия FFmpeg (по умолчанию `7.1`)
   - **Create a GitHub Release**: поставьте галочку, если хотите автоматически опубликовать релиз с готовыми zip/tar.gz архивами.

### Автоматическая сборка при релизе (Git Tag):
Если вы создадите и запушите тег с версией (например `v1.0.0`), GitHub Actions автоматически соберет бинарники для всех ОС и опубликует их в **Releases**:
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## 🛠️ Локальная сборка

Скрипты сборки расположены в папке `scripts/`:

### Сборка под Windows (через кросс-компиляцию на Linux/WSL):
```bash
sudo apt-get update && sudo apt-get install -y mingw-w64 nasm yasm pkg-config
bash scripts/build-windows.sh
# Результат: dist/ffmpeg-windows-x86_64.exe
```

### Сборка под Linux (статическая):
```bash
sudo apt-get update && sudo apt-get install -y build-essential nasm yasm pkg-config
ARCH=x86_64 bash scripts/build-linux.sh
# Результат: dist/ffmpeg-linux-x86_64
```

### Сборка под macOS:
```bash
brew install nasm yasm pkg-config
ARCH=universal bash scripts/build-macos.sh
# Результат: dist/ffmpeg-macos-universal
```

### Проверка сборки:
```bash
bash scripts/verify.sh ./dist/ffmpeg
```

---

## 📄 Лицензия

FFmpeg и LAME лицензированы под LGPL v2.1+ / LGPL v3.
Данный репозиторий содержит сборочные скрипты и конфигурации.
