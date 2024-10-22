#!/bin/bash

# Función para inicializar el repositorio
inicializar_repositorio() {
  directorio=$1
  carpeta_versiones="$directorio/.versiones"
  
  if [ ! -d "$carpeta_versiones" ]; then
    mkdir -p "$carpeta_versiones"
    echo "Repositorio inicializado en $directorio"
  else
    echo "El repositorio ya existe en $directorio"
  fi
}

# Función para registrar cambios
registrar_cambios() {
  directorio=$1
  archivo=$2
  mensaje=$3
  carpeta_versiones="$directorio/.versiones"
  timestamp=$(date +"%Y%m%d-%H%M%S")
  version="$archivo_$timestamp.zip"
  ruta_version="$carpeta_versiones/$version"

  # Comprimir el archivo
  zip -j "$ruta_version" "$directorio/$archivo"

  # Registrar el cambio en el log
  echo "$timestamp - $archivo - $mensaje" >> "$carpeta_versiones/historial_versiones.txt"
  echo "Versión guardada: $version"
}

# Función para listar versiones de un archivo
listar_versiones() {
  directorio=$1
  archivo=$2
  carpeta_versiones="$directorio/.versiones"
  versiones=$(ls "$carpeta_versiones" | grep "$archivo")
  echo "$versiones"
}

# Función para restaurar una versión
restaurar_version() {
  directorio=$1
  archivo=$2
  version=$3
  carpeta_versiones="$directorio/.versiones"

  unzip -o "$carpeta_versiones/$version" -d "$directorio"
  echo "$archivo restaurado a la versión $version"
}

# Función para comparar versiones de un archivo
comparar_versiones() {
  directorio=$1
  archivo=$2
  version1=$3
  version2=$4
  carpeta_versiones="$directorio/.versiones"

  unzip -p "$carpeta_versiones/$version1" "$archivo" > /tmp/version1.txt
  unzip -p "$carpeta_versiones/$version2" "$archivo" > /tmp/version2.txt

  diff -u /tmp/version1.txt /tmp/version2.txt

  # Limpieza de archivos temporales
  rm /tmp/version1.txt /tmp/version2.txt
}

# Función para eliminar versiones antiguas
eliminar_versiones_antiguas() {
  directorio=$1
  archivo=$2
  num_versiones_a_conservar=$3
  carpeta_versiones="$directorio/.versiones"
  versiones=$(ls "$carpeta_versiones" | grep "$archivo" | sort)

  total_versiones=$(echo "$versiones" | wc -l)
  if [ "$total_versiones" -gt "$num_versiones_a_conservar" ]; then
    versiones_a_eliminar=$(echo "$versiones" | head -n $(($total_versiones - $num_versiones_a_conservar)))

    for version in $versiones_a_eliminar; do
      rm "$carpeta_versiones/$version"
      echo "Eliminado $version"
    done
  else
    echo "No hay suficientes versiones antiguas para eliminar."
  fi
}

# Función para snapshot completo
snapshot_completo() {
  directorio=$1
  timestamp=$2
  carpeta_versiones="$directorio/.versiones"
  log_path="$carpeta_versiones/historial_versiones.txt"
  
  while read -r linea; do
    if [[ "$linea" == *"$timestamp"* ]]; then
      archivo=$(echo "$linea" | cut -d' ' -f3)
      version="$archivo"_"$timestamp.zip"
      restaurar_version "$directorio" "$archivo" "$version"
    fi
  done < "$log_path"
}

# Menú principal para interactuar con el sistema
menu() {
  echo "========================="
  echo " Sistema de Versionado "
  echo "========================="
  echo "1. Inicializar Repositorio"
  echo "2. Registrar Cambios"
  echo "3. Listar Versiones"
  echo "4. Restaurar Versión"
  echo "5. Comparar Versiones"
  echo "6. Eliminar Versiones Antiguas"
  echo "7. Snapshot Completo"
  echo "8. Salir"
  echo "========================="
  echo -n "Selecciona una opción: "
  read opcion

  case $opcion in
    1)
      echo -n "Ingresa el directorio del proyecto: "
      read directorio
      inicializar_repositorio "$directorio"
      ;;
    2)
      echo -n "Ingresa el directorio del proyecto: "
      read directorio
      echo -n "Ingresa el archivo a versionar: "
      read archivo
      echo -n "Ingresa un mensaje de cambio: "
      read mensaje
      registrar_cambios "$directorio" "$archivo" "$mensaje"
      ;;
    3)
      echo -n "Ingresa el directorio del proyecto: "
      read directorio
      echo -n "Ingresa el archivo: "
      read archivo
      listar_versiones "$directorio" "$archivo"
      ;;
    4)
      echo -n "Ingresa el directorio del proyecto: "
      read directorio
      echo -n "Ingresa el archivo: "
      read archivo
      versiones=$(listar_versiones "$directorio" "$archivo")
      echo "Versiones disponibles:"
      echo "$versiones"
      echo -n "Selecciona una versión para restaurar: "
      read version_a_restaurar
      restaurar_version "$directorio" "$archivo" "$version_a_restaurar"
      ;;
    5)
      echo -n "Ingresa el directorio del proyecto: "
      read directorio
      echo -n "Ingresa el archivo: "
      read archivo
      echo -n "Ingresa la primera versión a comparar: "
      read version1
      echo -n "Ingresa la segunda versión a comparar: "
      read version2
      comparar_versiones "$directorio" "$archivo" "$version1" "$version2"
      ;;
    6)
      echo -n "Ingresa el directorio del proyecto: "
      read directorio
      echo -n "Ingresa el archivo: "
      read archivo
      echo -n "Ingresa el número de versiones a conservar: "
      read num_versiones_a_conservar
      eliminar_versiones_antiguas "$directorio" "$archivo" "$num_versiones_a_conservar"
      ;;
    7)
      echo -n "Ingresa el directorio del proyecto: "
      read directorio
      echo -n "Ingresa el timestamp del snapshot: "
      read timestamp
      snapshot_completo "$directorio" "$timestamp"
      ;;
    8)
      exit 0
      ;;
    *)
      echo "Opción inválida"
      ;;
  esac
}

# Loop principal
while true; do
  menu
done
