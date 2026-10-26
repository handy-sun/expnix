# extract_forward_tgbot Deployment

Telegram bot for forwarding and organizing messages from TG channels.

## What It Does

- Forward messages to bot → extracts text + URLs → saves locally
- `/push` → pushes all saved content to a web notepad, returns URL
- `/image` → merge/stitch photos, generate GIF from 5+ images
- Video → GIF conversion for specified channels

## Config Analysis

Source: `configHandle.py` and `tgbotBehavior.py`

`push_dir` supports two modes (detected by reading source):
- **Local directory** (e.g. `./forward_message/`): uses `LocalReadWrite` to write files. Requires `domain` field for the URL returned to user.
- **URL** (e.g. `https://webnote.vfly2.com/`): uses `WebnoteReadWrite` to POST content.

Config file format (YAML):
```yaml
is_production: true
chat_id: <telegram_user_id>
bot_token: <bot_token>
push_dir: ./forward_message/    # or a URL
domain: http://host.docker.internal:1280/forward  # only needed for local push_dir
```

## Compose Config

```yaml
services:
  extforw:
    image: ahfeil/extract_forward_tgbot:latest
    container_name: extforw
    volumes:
      - ./configs:/ef_tgbot/configs
      - ./forward_message:/ef_tgbot/forward_message
    network_mode: bridge
    restart: always
```

Container WORKDIR is `/ef_tgbot`. Config expected at `configs/config.yaml` relative to workdir.

## Notes

- Server stores forwarded messages in plaintext — anyone with server access can read them
- Web notepad content auto-deleted after 15 days (when using author's hosted notepad)
- Supports multiple users (each user's data separated by chat_id)
- Image processing requires Chinese font (simsun.ttc) bundled in the Docker image
