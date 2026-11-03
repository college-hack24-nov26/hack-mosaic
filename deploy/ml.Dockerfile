FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir fastapi uvicorn xgboost pandas pydantic

COPY fastapi/main.py /app/main.py
COPY models/ /app/models/

# Compatibility symlinks so ml/fastapi/main.py (which uses raw Windows path strings)
# resolves the trained XGBoost model and feature schema on Linux without editing ml/.
RUN ln -s /app/models/outbreak_risk_xgboost.json '/app/c:\HA_022\ml\models\outbreak_risk_xgboost.json' && \
    ln -s /app/models/outbreak_feature_schema.json '/app/c:\HA_022\ml\models\outbreak_feature_schema.json'

EXPOSE 8001

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
