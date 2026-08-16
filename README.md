# FFmpeg Minimal Audio Builder for LosslessRobot

Сборщик ультра-минималистичного FFmpeg бинарника (размером **~3-5 МБ** вместо стандартных ~80-100 МБ), оптимизированного специально для десктопного приложения [LosslessRobot](https://github.com/yarchefis).

Поддерживает полностью автоматизированную и ручную кросс-платформенную сборку под **Windows (`x86_64`)**, **Linux (`x86_64`, `arm64`)** и **macOS (`Universal Binary` / `Apple Silicon arm64` / `Intel x86_64`)** через GitHub Actions. Всегда собирает самую последнюю актуальную версию (latest).

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

Вы можете запускать сборку с выбором платформ обычными **галочками (чекбоксами)**:

1. Перейдите во вкладку **Actions**: [https://github.com/yarchefis/ffmpeg-builder/actions](https://github.com/yarchefis/ffmpeg-builder/actions).
2. Выберите воркфлоу **Build Minimal FFmpeg**.
3. Нажмите **Run workflow** справа вверху.
4. Отметьте нужные платформы галочками:
   - ☑ **Windows (x86_64 .exe)**
   - ☑ **Linux (x86_64 static)**
   - ☐ **Linux (ARM64 static)**
   - ☑ **macOS Universal (Apple Silicon + Intel)**
   - ☐ **macOS (Apple Silicon arm64 only)**
   - ☐ **macOS (Intel x86_64 only)**
   - ☐ **Publish GitHub Release** (поставьте галочку, если нужно опубликовать релиз с готовыми архивами)
5. Нажмите зеленую кнопку **Run workflow**.

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
sudo apt-get update && sudo apt-get install -y mingw-w64 nasm yasm pkg-config git
bash scripts/build-windows.sh
# Результат: dist/ffmpeg-windows-x86_64.exe
```

### Сборка под Linux (статическая):
```bash
sudo apt-get update && sudo apt-get install -y build-essential nasm yasm pkg-config git
ARCH=x86_64 bash scripts/build-linux.sh
# Результат: dist/ffmpeg-linux-x86_64
```

### Сборка под macOS:
```bash
brew install nasm yasm pkg-config git
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
