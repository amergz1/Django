#!/bin/sh
set -e

# ── Worker de Celery + Beat embebidos (Render Free) ──────────────────
# Se activan con CELERY_EMBEDDED_WORKER=1 y requieren REDIS_URL.
if [ "${CELERY_EMBEDDED_WORKER:-0}" = "1" ] && [ -n "${REDIS_URL:-}" ]; then
    BEAT_OPTS=""
    if [ "${CELERY_EMBEDDED_BEAT:-1}" = "1" ]; then
        BEAT_OPTS="--beat --schedule=/tmp/celerybeat-schedule"
        echo "==> [entrypoint] Celery Beat embebido ACTIVADO (reporte diario ${REPORTE_DIARIO_HORA:-08:00} hora MX)."
    fi
    echo "==> [entrypoint] Iniciando worker de Celery embebido (cola erp_django)..."
    # shellcheck disable=SC2086
    celery -A core worker \
        --loglevel=info \
        --queues=erp_django \
        --pool=solo \
        --without-gossip --without-mingle --without-heartbeat \
        $BEAT_OPTS &
else
    echo "==> [entrypoint] Worker de Celery embebido DESACTIVADO."
fi

# ── Servidor web (debe ser la última línea) ──────────────────────────
exec gunicorn core.wsgi \
    --bind 0.0.0.0:${PORT:-8000} \
    --workers 2 \
    --timeout 120 \
    --log-file -