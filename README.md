# Liquidación de la cosecha de una finca cafetera

@moduledoc """
  - autor_1: Daniel Yizack Gutiérrez Ruíz
  - autor_2: Jhon Fredy Sarchi Vélez
  - fecha: Octubre 2026
  """

## Archivos del proyecto

- `datos.exs`: contiene los recolectores, lotes y pesajes usados para probar la aplicación.
- `util.exs`: módulo de entrada y salida.
- `validacion.exs`: revisa el formato y las reglas de validez de los pesajes.
- `liquidacion.exs`: calcula valor de pesajes, bonificaciones, alimentación y pago neto.
- `reportes.exs`: construye los ocho reportes, los rankings, la combinación de fincas y el desprendible.
- `programa.exs`: contiene el flujo principal y la interacción con el usuario.

## Compilación

Abrir una terminal en esta carpeta y ejecutar:

```bash
elixirc util.exs
elixirc validacion.exs
elixirc liquidacion.exs
elixirc reportes.exs
elixirc datos.exs
```

Cuando se cambie `datos.exs`, se debe volver a compilar los módulos antes de ejecutar el programa.

## Ejecución

```bash
elixir programa.exs
```

El programa solicita un pesaje adicional. Si se presiona Enter sin escribir información, continúa con los datos cargados. Después muestra los reportes, los rankings, la combinación de producción y solicita una sola vez el código de un recolector para mostrar su desprendible.

## Estructuras utilizadas

La solución trabaja con módulos, funciones, pipe, `cond`, `case`, guards, `with`, tuplas de resultado, listas, mapas, `Enum`, `Keyword` y funciones de `Map`.

No se utilizó recursividad, `try/rescue`, structs, streams, procesos, agentes, GenServer, ETS, bases de datos ni Mix.
