# E-Commerce Analytics DWH with dbt (data build tool)

Производственный проект по трансформации данных (ELT) на базе **dbt Core** и **PostgreSQL 17**. Проект демонстрирует переход от сырых транзакционных таблиц интернет-магазина (по структуре классического датасета Kaggle *Brazilian E-Commerce / Olist*) к аналитической модели «Звезда» (Kimball) с инкрементальной загрузкой, автоматизированными тестами качества данных и бизнес-метриками (RFM-сегментация, LTV, Cohort Retention).

## 1. Архитектура DWH (Слои трансформации)

```
[ Raw Layer (Postgres) ] ──> [ Staging (Views) ] ──> [ Intermediate (Ephemeral) ] ──> [ Marts (Tables / Incremental) ]
  raw_orders                  stg_orders              int_order_payments               fct_orders (Incremental)
  raw_customers               stg_customers           int_customer_rfm                 dim_customers (Table)
  raw_order_items             stg_order_items                                          mart_cohort_retention (Table)
```

* **Staging (`models/staging/`)**: Очистка сырых данных, приведение типов, переименование полей в единый `snake_case`, дедупликация. Материализуется как `view` для экономии места.
* **Intermediate (`models/intermediate/`)**: Промежуточные бизнес-расчёты (агрегация платежей по заказу, расчёт RFM-метрик). Материализуется как `ephemeral` (встраивается как CTE, не засоряя БД).
* **Marts (`models/marts/`)**: Финальные витрины для BI-аналитики. Таблица фактов `fct_orders` настроена в режиме **`incremental`** (`merge` / `delete+insert`) для обработки только новых и изменённых заказов.

## 2. Реализованные практики dbt
* **Incremental Models**: Оптимизация времени сборки `fct_orders` за счёт фильтрации по `updated_at` с помощью макроса `is_incremental()`.
* **Data Quality & Testing (`schema.yml`)**: Встроенные тесты (`unique`, `not_null`, `accepted_values`, `relationships`) и кастомный singular-тест `assert_positive_order_amount.sql`.
* **Jinja & Macros (`macros/cents_to_currency.sql`)**: Переиспользуемый макрос для безопасной конвертации копеек/центов в валюту с округлением.
* **Snapshots (SCD Type 2)**: Отслеживание истории изменения статусов заказов и адресов клиентов (`snapshots/orders_snapshot.sql`).


## 3. Пошаговая инструкция запуска

1. **Запустите PostgreSQL в Docker:**
   ```bash
   docker-compose up -d
   ```
2. **Установите dbt-postgres и настройте профиль:**
   ```bash
   pip install dbt-postgres
   export DBT_PROFILES_DIR=$(pwd)
   ```
3. **Загрузите тестовые справочники (Seeds) и запустите сборку моделей:**
   ```bash
   dbt seed
   dbt run
   ```
4. **Запустите тесты качества данных и сгенерируйте документацию (Data Lineage):**
   ```bash
   dbt test
   dbt docs generate
   dbt docs serve --port 8081
   ```
ce-dbt-postgres-dwh
