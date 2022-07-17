-- Добавляем столбец со статусом отгрузки, по умолчанию будет заполнен, как отгружен
alter table staging.user_order_log add column status text default 'shipped';