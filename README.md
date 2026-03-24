# UD7 – El lenguaje SQL: Manipulación de Datos y Gestión de Transacciones

Para esta práctica estaremos trabajando con el modelo de ejemplo de oracle Order Entry.

Las tablas originales del esquema `OE` no se modifican directamente; en su lugar se trabaja con las copias que voy a crear acontinuación (`productos_u4` e `inventario_u4`).

---

## Paso 1 – Espejo de Datos

Antes de comenzar cualquier operación DML, se crean copias de las tablas originales del esquema `OE` para no alterar los datos maestros:

```sql
CREATE TABLE productos_u4  AS SELECT * FROM OE.PRODUCT_INFORMATION;
CREATE TABLE inventario_u4 AS SELECT * FROM OE.INVENTORIES;
```

Estas tablas heredan la estructura y los datos de las originales, pero **no las restricciones de integridad referencial** (claves foráneas).

![alt text](img/img_1.png)

---

## Paso 2 – Bloque de Inserción (INSERT)

La sentencia `INSERT` permite añadir nuevas filas a una tabla. Se han practicado diez variantes distintas de inserción.

### 2.1 – Simple

Inserción directa especificando solo las columnas necesarias:

```sql
INSERT INTO productos_u4 (product_id, product_name, list_price)
VALUES (7000, 'Cable HDMI 2.1', 25);
```

Las columnas no indicadas reciben `NULL` automáticamente si no tienen valor por defecto.

![alt text](img/img_2.1.png)


### 2.2 – Columnas específicas

Se pueden omitir columnas opcionales. Oracle asignará `NULL` a las no incluidas:

```sql
INSERT INTO productos_u4 (product_id, product_name, category_id)
VALUES (7001, 'Hub USB-C', 10);
```

![alt text](img/img_2.2.png)


### 2.3 – Uso de Nulos

Se insertan todos los campos explícitamente, dejando `warranty_period` como `NULL`:

```sql
INSERT INTO productos_u4 (
    product_id, product_name, product_description, category_id,
    weight_class, warranty_period, supplier_id, product_status,
    list_price, min_price, catalog_url
)
VALUES (
    7002, 'Teclado Mecánico', 'Teclado mecánico retroiluminado RGB', 10,
    1, NULL, 102, 'orderable', 89.99, 45.00, 'http://catalog.example.com/7002'
);
```

![alt text](img/img_2.3.png)


### 2.4 – Sintaxis de Fecha con SYSDATE

Se crea una tabla de log y se registra la fecha actual usando la función `SYSDATE`:

```sql
CREATE TABLE log_pedidos (
    log_id      NUMBER PRIMARY KEY,
    descripcion VARCHAR2(200),
    fecha_log   DATE
);

INSERT INTO log_pedidos (log_id, descripcion, fecha_log)
VALUES (1, 'Registro de prueba con SYSDATE', SYSDATE);
```

`SYSDATE` devuelve la fecha y hora actuales del servidor Oracle.

![alt text](img/img_2.4.png)


### 2.5 – Copia de fila

Se inserta una copia exacta del producto 1797 con un ID diferente mediante una subconsulta:

```sql
INSERT INTO productos_u4
SELECT 7003, product_name, product_description, category_id,
       weight_class, warranty_period, supplier_id, product_status,
       list_price, min_price, catalog_url
FROM OE.PRODUCT_INFORMATION
WHERE product_id = 1797;
```

![alt text](img/img_2.5.png)


### 2.6 – Inserción Masiva

Se insertan múltiples filas en una sola sentencia usando `INSERT ... SELECT`. El filtro `NOT IN` evita duplicados:

```sql
INSERT INTO productos_u4
SELECT *
FROM OE.PRODUCT_INFORMATION
WHERE list_price > 5000
  AND product_id NOT IN (SELECT product_id FROM productos_u4);
```

![alt text](img/img_2.6.png)


### 2.7 – Subconsulta con Filtro

Inserta productos de la categoría 11 que todavía no existen en la tabla destino:

```sql
INSERT INTO productos_u4
SELECT *
FROM OE.PRODUCT_INFORMATION
WHERE category_id = 11
  AND product_id NOT IN (SELECT product_id FROM productos_u4);
```

![alt text](img/img_2.7.png)


### 2.8 – Carga Parcial

Solo se insertan dos columnas (`product_id` y `product_name`) de los productos con stock en el almacén 1:

```sql
INSERT INTO productos_u4 (product_id, product_name)
SELECT DISTINCT pi.product_id, pi.product_name
FROM OE.PRODUCT_INFORMATION pi
WHERE pi.product_id IN (
    SELECT product_id FROM OE.INVENTORIES WHERE warehouse_id = 1
)
AND pi.product_id NOT IN (SELECT product_id FROM productos_u4);
```

![alt text](img/img_2.8.png)


### 2.9 – Cálculo en Inserción

El valor de `list_price` se calcula dinámicamente como el doble del precio medio de la categoría 10:

```sql
INSERT INTO productos_u4 (product_id, product_name, category_id, list_price)
VALUES (
    7005,
    'Producto Calculado Cat10',
    10,
    (SELECT AVG(list_price) * 2 FROM OE.PRODUCT_INFORMATION WHERE category_id = 10)
);
```

![alt text](img/img_2.9.png)


### 2.10 – Multitabla con SELECT

Se crea una tabla auxiliar `precios_altos` y se puebla con todos los productos cuyo precio supera 1000:

```sql
CREATE TABLE precios_altos AS
SELECT product_id, product_name, list_price
FROM productos_u4 WHERE 1 = 0;

INSERT INTO precios_altos (product_id, product_name, list_price)
SELECT product_id, product_name, list_price
FROM productos_u4
WHERE list_price > 1000;
```

![alt text](img/img_2.10.png)

---

