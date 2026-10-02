defmodule Validacion do
  @moduledoc """
  Este módulo reúne las funciones que revisan los datos de cada pesaje,
  cada validación devuelve una tupla de resultado para indicar si el dato
  puede continuar en el proceso o debe ser rechazado con un motivo.
  - autor_1: Daniel Yizack Gutiérrez Ruíz
  - autor_2: Jhon Fredy Sarchi Vélez
  - fecha: Octubre 2026
  """

  @dias_cosecha 6
  @max_kilos_pesaje 250

  @doc """
  Función que valida un pesaje en un orden definido,
  devuelve {:ok, pesaje} cuando supera todas las verificaciones o
  {:error, motivo} cuando encuentra la primera regla que no se cumple.
  """
  def validar_pesaje(pesaje, recolectores, lotes) do
    with {:ok, pesaje} <- validar_recolector(pesaje, recolectores),
         {:ok, pesaje} <- validar_lote(pesaje, lotes),
         {:ok, pesaje} <- validar_dia(pesaje),
         {:ok, pesaje} <- validar_kilos(pesaje),
         {:ok, pesaje} <- validar_porcentaje(pesaje) do
      {:ok, pesaje}
    end
  end

  @doc """
  Esta función recorre todos los pesajes y los separa en dos listas:
  pesajes válidos y pesajes rechazados con su motivo.
  """
  def separar_pesajes(pesajes, recolectores, lotes) do
    Enum.reduce(pesajes, {[], []}, fn pesaje, {validos, rechazados} ->
      case validar_pesaje(pesaje, recolectores, lotes) do
        {:ok, pesaje_valido} ->
          {validos ++ [pesaje_valido], rechazados}

        {:error, motivo} ->
          rechazo = %{pesaje: pesaje, motivo: motivo}
          {validos, rechazados ++ [rechazo]}
      end
    end)
  end

  @doc """
  Función que convierte una línea con el formato recolector;lote;dia;kilos;verdes
  en un mapa de pesaje, si la cantidad de campos o alguno de los valores numéricos no tiene
  el formato esperado, devuelve {:error, :formato_invalido}.
  """
  def convertir_linea_pesaje(linea) do
    campos =
      linea
      |> String.split(";")
      |> Enum.map(fn campo -> String.trim(campo) end)

    with [recolector, lote, dia_texto, kilos_texto, verdes_texto] <- campos,
         {:ok, dia} <- convertir_entero(dia_texto),
         {:ok, kilos} <- convertir_numero(kilos_texto),
         {:ok, verdes} <- convertir_numero(verdes_texto) do
      {:ok, %{recolector: recolector, lote: lote, dia: dia, kilos: kilos, verdes: verdes}}
    else
      _ -> {:error, :formato_invalido}
    end
  end

  @doc"""
  Esta función verifica que el código del recolector aparezca en la lista
  de recolectores.
  """
  defp validar_recolector(pesaje, recolectores) do
    existe = Enum.any?(recolectores, fn recolector -> recolector.codigo == pesaje.recolector end)

    case existe do
      true -> {:ok, pesaje}
      false -> {:error, :recolector_desconocido}
    end
  end

  @doc"""
  Función que verifica que el identificador del lote
  aparezca en la lista de lotes.
  """
  defp validar_lote(pesaje, lotes) do
    existe = Enum.any?(lotes, fn lote -> lote.id == pesaje.lote end)

    case existe do
      true -> {:ok, pesaje}
      false -> {:error, :lote_desconocido}
    end
  end

  @doc"""
  Esta función comprueba que el día sea entero y esté dentro
  de los días de cosecha.
  """
  defp validar_dia(pesaje) do
    case pesaje.dia do
      dia when is_integer(dia) and dia >= 1 and dia <= @dias_cosecha ->
        {:ok, pesaje}

      _ ->
        {:error, :dia_invalido}
    end
  end

  @doc"""
  Función que comprueba que los kilos sean numéricos y estén dentro
  del rango permitido.
  """
  defp validar_kilos(pesaje) do
    case pesaje.kilos do
      kilos when is_number(kilos) and kilos > 0 and kilos <= @max_kilos_pesaje ->
        {:ok, pesaje}

      _ ->
        {:error, :kilos_fuera_de_rango}
    end
  end

  @doc"""
  Esta función comprueba que el porcentaje de verdes sea numérico
  y esté entre 0 y 100.
  """
  defp validar_porcentaje(pesaje) do
    case pesaje.verdes do
      verdes when is_number(verdes) and verdes >= 0 and verdes <= 100 ->
        {:ok, pesaje}

      _ ->
        {:error, :porcentaje_invalido}
    end
  end

  @doc"""
  Esta función convierte un texto a entero únicamente cuando todo el texto
  corresponde al número.
  """
  defp convertir_entero(texto) do
    case Integer.parse(texto) do
      {numero, ""} -> {:ok, numero}
      _ -> {:error, :formato_invalido}
    end
  end

  @doc"""
  Esta función convierte un texto a número decimal únicamente
  cuando todo el texto es válido.
  """
  defp convertir_numero(texto) do
    case Float.parse(texto) do
      {numero, ""} -> {:ok, numero}
      _ -> {:error, :formato_invalido}
    end
  end
end
