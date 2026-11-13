# smux
smux - Bulk multiplexer script for series using MKVToolNix for Windows

The script processes all video files, audio files, and subtitle files in a folder. Files with identical names are combined into a single video file.

Audio and video files support "suffixes" of the following form:
```
MySeries.mkv
MySeries.DubStudioName.rus.mka
MySeries.cr.signs.rus.ass
```

### Supported formats
- Video: `.mkv` `.mp4` `.avi` `.ts` `.m4v` `.webm` `.mov` `.wmv`

- Audio: `.mka` `.ac3` `.eac3` `.dts` `.flac` `.wav` `.aac` `.m4a` `.mp3` `.opus` `.thd`

- Subtitles: `.ass` `.ssa` `.srt` `.sub` `.sup` `.vtt`

---
## mux.bat
Initial and working script for bulk multiplexing

### Usage
Place the `mux.bat` script, the video files, audio files, and subtitle files in the same folder, then run the script.

---

## smux.bat \[WIP\]
**WORK IN PROGRESS**

An improved script that supports parameters for the source folder, the audio folder, the subtitle folder, and the output folder.

### Usage

Place the `smux.bat` script, the video files, audio files, and subtitle files in the same folder, then run the script.

OR

```
smux.bat [-v VIDEO_DIR] [-a AUDIO_DIR] [-s SUB_DIR] [-o OUT_DIR]

  -v  Video folder (default: script folder)
  -a  Audio folder (default: script folder; relative path - from VIDEO_DIR)
  -s  Subtitle folder (default: script folder; relative path - from VIDEO_DIR)
  -o  Output folder (default: Completed in script folder)
```

OR 

```
smux.bat -h
```
