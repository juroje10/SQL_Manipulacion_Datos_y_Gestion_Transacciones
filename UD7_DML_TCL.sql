-- ============================================================
-- PASO 1: ESPEJO DE DATOS (preparación del entorno)
-- ============================================================
CREATE TABLE productos_u4  AS SELECT * FROM OE.PRODUCT_INFORMATION;
CREATE TABLE inventario_u4 AS SELECT * FROM OE.INVENTORIES;


-- ============================================================
-- PASO 2: BLOQUE DE INSERCIÓN (INSERT)
-- ============================================================

-- Ejercicio 2.1 - Simple
-- Inserta un producto con ID 7000, nombre 'Cable HDMI 2.1' y precio 25
INSERT INTO productos_u4 (product_id, product_name, list_price)
VALUES (7000, 'Cable HDMI 2.1', 25);

-- Ejercicio 2.2 - Columnas específicas
-- Inserta el producto 7001 llamado 'Hub USB-C' solo con ID, nombre y category_id = 10
INSERT INTO productos_u4 (product_id, product_name, category_id)
VALUES (7001, 'Hub USB-C', 10);

-- Ejercicio 2.3 - Uso de Nulos
-- Inserta el producto 7002 con todos los campos pero deja warranty_period como NULL
INSERT INTO productos_u4 (
    product_id, product_name, product_description, category_id,
    weight_class, warranty_period, supplier_id, product_status,
    list_price, min_price, catalog_url
)
VALUES (
    7002, 'Teclado Mecánico', 'Teclado mecánico retroiluminado RGB', 10,
    1, NULL, 102, 'orderable',
    89.99, 45.00, 'http://catalog.example.com/7002'
);

-- Ejercicio 2.4 - Sintaxis de Fecha con SYSDATE
-- Creamos una tabla de log y registramos un pedido con la fecha actual
CREATE TABLE log_pedidos (
    log_id       NUMBER PRIMARY KEY,
    descripcion  VARCHAR2(200),
    fecha_log    DATE
);

INSERT INTO log_pedidos (log_id, descripcion, fecha_log)
VALUES (1, 'Registro de prueba con SYSDATE', SYSDATE);

-- Ejercicio 2.5 - Copia de fila
-- Inserta un nuevo producto idéntico al 1797 pero con ID 7003
INSERT INTO productos_u4
SELECT 7003, product_name, product_description, category_id,
       weight_class, warranty_period, supplier_id, product_status,
       list_price, min_price, catalog_url
FROM OE.PRODUCT_INFORMATION
WHERE product_id = 1797;

-- Ejercicio 2.6 - Inserción Masiva
-- Inserta en productos_u4 todos los productos de la tabla original con list_price > 5000
INSERT INTO productos_u4
SELECT *
FROM OE.PRODUCT_INFORMATION
WHERE list_price > 5000
  AND product_id NOT IN (SELECT product_id FROM productos_u4);

-- Ejercicio 2.7 - Subconsulta con Filtro
-- Inserta productos de la categoría 11 que no existan actualmente en productos_u4
INSERT INTO productos_u4
SELECT *
FROM OE.PRODUCT_INFORMATION
WHERE category_id = 11
  AND product_id NOT IN (SELECT product_id FROM productos_u4);

-- Ejercicio 2.8 - Carga Parcial
-- Inserta solo product_id y product_name de los productos con stock en el almacén 1
INSERT INTO productos_u4 (product_id, product_name)
SELECT DISTINCT pi.product_id, pi.product_name
FROM OE.PRODUCT_INFORMATION pi
WHERE pi.product_id IN (
    SELECT product_id
    FROM OE.INVENTORIES
    WHERE warehouse_id = 1
)
AND pi.product_id NOT IN (SELECT product_id FROM productos_u4);

-- Ejercicio 2.9 - Cálculo en Inserción
-- Inserta producto 7005 con list_price = doble del precio medio de la categoría 10
INSERT INTO productos_u4 (product_id, product_name, category_id, list_price)
VALUES (
    7005,
    'Producto Calculado Cat10',
    10,
    (SELECT AVG(list_price) * 2 FROM OE.PRODUCT_INFORMATION WHERE category_id = 10)
);

-- Ejercicio 2.10 - Multitabla (INSERT con SELECT)
-- Crea tabla precios_altos e inserta los productos con precio > 1000
CREATE TABLE precios_altos AS
SELECT product_id, product_name, list_price
FROM productos_u4
WHERE 1 = 0; -- estructura sin datos

INSERT INTO precios_altos (product_id, product_name, list_price)
SELECT product_id, product_name, list_price
FROM productos_u4
WHERE list_price > 1000;


-- ============================================================
-- PASO 3: BLOQUE DE MODIFICACIÓN (UPDATE)
-- ============================================================

-- Ejercicio 3.1 - Directo
-- Cambia el product_status a 'obsolete' para el producto 1797
UPDATE productos_u4
SET product_status = 'obsolete'
WHERE product_id = 1797;

-- Ejercicio 3.2 - Múltiple
-- Cambia min_price a 50 y list_price a 80 del producto 7000
UPDATE productos_u4
SET min_price  = 50,
    list_price = 80
WHERE product_id = 7000;

-- Ejercicio 3.3 - Filtro Simple
-- Incrementa en 10 el precio de todos los productos de la categoría 12
UPDATE productos_u4
SET list_price = list_price + 10
WHERE category_id = 12;

-- Ejercicio 3.4 - Uso de LIKE
-- Pone en 'discontinued' todos los productos cuyo nombre empiece por 'Software'
UPDATE productos_u4
SET product_status = 'discontinued'
WHERE product_name LIKE 'Software%';

-- Ejercicio 3.5 - Basado en NULL
-- Asigna min_price = 5 a todos los productos que tengan ese campo como nulo
UPDATE productos_u4
SET min_price = 5
WHERE min_price IS NULL;

-- Ejercicio 3.6 - Cálculo Porcentual
-- Rebaja un 20% el precio de los productos con weight_class = 5
UPDATE productos_u4
SET list_price = list_price * 0.80
WHERE weight_class = 5;

-- Ejercicio 3.7 - Subconsulta Simple
-- Sube el precio 100 a todos los productos de la categoría 'Software/Other'
UPDATE productos_u4
SET list_price = list_price + 100
WHERE category_id = (
    SELECT category_id
    FROM OE.CATEGORIES_TAB
    WHERE category_name = 'Software/Other'
);

-- Ejercicio 3.8 - Update Correlacionado
-- Actualiza min_price de productos_u4 para que sea igual al precio más bajo
-- registrado para ese producto en order_items
UPDATE productos_u4 p
SET p.min_price = (
    SELECT MIN(oi.unit_price)
    FROM OE.ORDER_ITEMS oi
    WHERE oi.product_id = p.product_id
)
WHERE EXISTS (
    SELECT 1
    FROM OE.ORDER_ITEMS oi
    WHERE oi.product_id = p.product_id
);

-- Ejercicio 3.9 - Condición de Existencia
-- Cambia el estado a 'available' solo de los productos con al menos 1 unidad en inventario_u4
UPDATE productos_u4
SET product_status = 'available'
WHERE product_id IN (
    SELECT product_id
    FROM inventario_u4
    WHERE quantity_on_hand >= 1
);

-- Ejercicio 3.10 - Lógica Compleja
-- Si un producto tiene list_price superior a la media global, redúcelo un 5%
UPDATE productos_u4
SET list_price = list_price * 0.95
WHERE list_price > (SELECT AVG(list_price) FROM productos_u4);


-- ============================================================
-- PASO 4: BLOQUE DE BORRADO (DELETE)
-- ============================================================

-- Ejercicio 4.1 - ID Específico
-- Borra el producto 7000
DELETE FROM productos_u4
WHERE product_id = 7000;

-- Ejercicio 4.2 - Filtro de Texto
-- Borra todos los productos que contengan la palabra 'Test' en su descripción
DELETE FROM productos_u4
WHERE product_description LIKE '%Test%';

-- Ejercicio 4.3 - Rango Numérico
-- Borra los productos con list_price entre 0 y 1
DELETE FROM productos_u4
WHERE list_price BETWEEN 0 AND 1;

-- Ejercicio 4.4 - Estado y Categoría
-- Borra productos de la categoría 10 que estén 'under development'
DELETE FROM productos_u4
WHERE category_id = 10
  AND product_status = 'under development';

-- Ejercicio 4.5 - Sin Inventario
-- Borra de productos_u4 los que no tengan ninguna entrada en inventario_u4
DELETE FROM productos_u4
WHERE product_id NOT IN (
    SELECT DISTINCT product_id FROM inventario_u4
);

-- Ejercicio 4.6 - Subconsulta de Agregación
-- Borra los productos cuyo min_price sea el más bajo de toda la tabla
DELETE FROM productos_u4
WHERE min_price = (SELECT MIN(min_price) FROM productos_u4);

-- Ejercicio 4.7 - Relacional
-- Borra los productos que nunca hayan sido vendidos (no aparecen en order_items)
DELETE FROM productos_u4
WHERE product_id NOT IN (
    SELECT DISTINCT product_id FROM OE.ORDER_ITEMS
);

-- Ejercicio 4.8 - Basado en Almacén
-- Borra del inventario los registros de productos en almacenes situados en 'Japan'
DELETE FROM inventario_u4
WHERE warehouse_id IN (
    SELECT w.warehouse_id
    FROM OE.WAREHOUSES w
    JOIN OE.LOCATIONS l   ON w.location_id   = l.location_id
    JOIN OE.COUNTRIES c   ON l.country_id    = c.country_id
    WHERE c.country_name = 'Japan'
);

-- Ejercicio 4.9 - Doble Condición Subquery
-- Borra productos cuya categoría tenga menos de 5 productos registrados
DELETE FROM productos_u4
WHERE category_id IN (
    SELECT category_id
    FROM productos_u4
    GROUP BY category_id
    HAVING COUNT(*) < 5
);

-- Ejercicio 4.10 - Limpieza Total
-- Borra todos los registros insertados en el Paso 2 (IDs entre 7000 y 8000)
DELETE FROM productos_u4
WHERE product_id BETWEEN 7000 AND 8000;


-- ============================================================
-- PASO 5: TRANSACCIONES Y CONCURRENCIA
-- ============================================================

-- Preparación: tabla para los escenarios de transacciones
CREATE TABLE cuenta_bancaria (
    id      NUMBER PRIMARY KEY,
    titular VARCHAR2(50),
    saldo   NUMBER(10,2)
);

INSERT INTO cuenta_bancaria VALUES (1, 'Usuario A', 1000);
INSERT INTO cuenta_bancaria VALUES (2, 'Usuario B', 2000);
COMMIT;



-- Escenario 1: Principio de Atomicidad (All-or-Nothing)

-- Paso 1: Restamos 500€ a la cuenta 1 (esto funciona)
UPDATE cuenta_bancaria SET saldo = saldo - 500 WHERE id = 1;

-- Paso 2: Intentamos sumar 500€ a la cuenta 99
UPDATE cuenta_bancaria SET saldo = saldo + 500 WHERE id = 99;
-- la cuenta 99 no existe → estado inconsistente.

-- Paso 3: Verificación del estado
SELECT * FROM cuenta_bancaria;

-- Paso 4: Deshacemos el estado inconsistente
ROLLBACK;

-- Verificación después del ROLLBACK
SELECT * FROM cuenta_bancaria;



-- Escenario 2: Puntos de Guardado y Deshacer Parcial

-- Paso 1: Subimos el saldo de todos un 10% y creamos un savepoint
UPDATE cuenta_bancaria SET saldo = saldo * 1.10;
SAVEPOINT sp_subida;

-- Paso 2: Insertamos un nuevo titular y creamos otro savepoint
INSERT INTO cuenta_bancaria VALUES (3, 'Usuario C', 500);
SAVEPOINT sp_nuevo_usuario;

-- Paso 3: Borramos accidentalmente a todos los usuarios
DELETE FROM cuenta_bancaria;

-- Paso 4: Recuperamos hasta el savepoint sp_nuevo_usuario
-- (se deshace el DELETE, pero se conservan los dos pasos anteriores)
ROLLBACK TO SAVEPOINT sp_nuevo_usuario;

-- Verificación: deben aparecer los 3 usuarios con saldos ya actualizados
SELECT * FROM cuenta_bancaria;

-- Confirmamos el estado correcto
COMMIT;



-- Escenario 4: El "Commit Fantasma" (DDL implica COMMIT)

-- Paso 1: Borramos al Usuario 2 (sin COMMIT)
DELETE FROM cuenta_bancaria WHERE id = 2;

-- Paso 2: Creamos una tabla DDL (esto ejecuta un COMMIT implícito en Oracle)
CREATE TABLE log_errores (msg VARCHAR2(100));

-- Paso 3: Intentamos deshacer
ROLLBACK;

-- Paso 4: Verificación
SELECT * FROM cuenta_bancaria;











