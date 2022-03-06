#!/bin/bash
echo "Bienvenido al gestor de Squid"
#Comprobación de si el servicio esta o no instalado
instalado=`sudo apt list squid 2>/dev/null | grep -Ee "instalado" -o`
if [[ -z $instalado ]]
then
	while true
	do
		#Automatización de la instalación del paquete
        	read -p "¿Desea instalar squid? (yes/no): " instalacion
                if [ $instalacion == "yes" ]
                then
                        sudo apt update &>/dev/null
                        sudo apt install squid -y &>/dev/null
      			instalado=`sudo apt list squid 2>/dev/null | grep -Ee "instalado" -o`
			#Comprobación de error en la instalación
			if [[ -z $instalado ]]
			then
				#Comprobación de conectividad con repositorio oficial del sistema, para dar un error concreto en caso de fallo de la instalación
				conexion=`nslookup es.archive.ubuntu.com | grep "SERVFAIL"`
				if [ $conexion == "SERVFAIL" ]
				then
					echo "Se ha producido un error durante la instalación debido a un error de conexión a internet. Compruebe su conexión y sus parametros de red, por favor."
				else
					echo "Se ha producido un error durante la instalación del paquete"
				fi
			fi
			break
		#En caso de no tener instalado squid y no querer hacerlo, finaliza el programa
                elif [ $instalacion == "no" ]
                then
                        echo "Este programa es un script de administración de Squid."
			break
		else
			echo "Opcion incorrecta"
                fi
	done

elif [[ $instalado == "instalado" ]]
then
        while true
        do
                echo "Menú del servicio squid"
                echo "1 - Actualización del servicio"
                echo "2 - Modificación de parametros del servidor"
                echo "3 - Listas de control de acceso"
                echo "4 - Reglas de control de acceso"
                echo "5 - Salir del programa"
                read -p "¿Que opcion desea ejecutar?: " opcion
		if [ $opcion == "1" ]
                then
                        actual_version=`sudo apt-cache policy squid | grep "Instalados" | cut -d " " -f 4`
                        ultima_version=`sudo apt-cache policy squid | grep "Candidato" | cut -d " " -f 5`
                        if [ $actual_version == $ultima_version ]
                        then
                                echo "Tiene instalada la ultima versión de Squid ($actual_version)"
                        else
                                while true
				do
					read -p "No tiene instalada la ultima versión de Squid. ¿Desea instalarla?: " actualizacion
					if [ $actualizacion == "yes" ]
					then
						sudo apt update &>/dev/null
                        			sudo apt install squid -y &>/dev/null
						break
					elif [ $actualización == "no" ]
					then
						break
					else
						echo "Opcion no contemplada"
					fi
				done
                        fi
                elif [ $opcion == "2" ]
			then
			while true
		        do
                		echo "Cambios del servicio"
                		echo "1 - Cambio de puerto"
                		echo "2 - Modificación de cache"
                		echo "3 - Salir"
                		read -p "¿Que opcion desea ejecutar?: " opcion2
				if [ $opcion2 == "1" ]
				then
				re='^[0-9]+$'
					while true
					do
						#Modificación del puerto del servicio. Validación con puertos de red actuales
						read -p "Indique un numero de puerto: " puerto
						if [[ $puerto -ge "0" ]] && [[ $puerto -le "65536" ]] && [[ $puerto =~ $re ]]
						then
							sudo sed -Ee "/^(#|)(http_port)/c\http_port $puerto" /etc/squid/squid.conf -i
							break
						else 
                                                        echo "Valor no permitido"
                                                fi
					done
					break
				elif [ $opcion2 == "2" ]
				then
					while true
                                        do
						#Modificación del tamaño de la cache del servicio. Validación de que sea un valor númerico
                                                read -p "Indique un tamaño de caché: " cache
                                                if [[ $cache -gt "0" ]] && [[ $cache =~ $re ]] 
                                                then
                                                        sudo sed -Ee "/^(#|)(cache_dir)/c\cache_dir ufs /var/spool/squid $cache 16 256" /etc/squid/squid.conf -i
							break
						else 
							echo "Valor no permitido"
                                 		fi
                                        done
					break
				elif [ $opcion2 == "3" ]
				then
					break
				else
					echo "Opcion no contemplada"
				fi
			done
		elif [ $opcion == "3" ]
			then
			while true
		        do
				#En este caso se permite la creación y eliminación de ACL. Se crea el archivo de listas si no existe.
                		echo "Listas de control de acceso"
                		echo "1 - Crear lista de control de acceso"
                		echo "2 - Eliminar lista de control de acceso"
                		echo "3 - Salir"
                		read -p "¿Que opcion desea ejecutar?: " opcion2
				if ! [ -f "/etc/squid/conf.d/listas.conf" ]
                                then
                                       sudo touch /etc/squid/conf.d/listas.conf
				       sudo chmod o+w /etc/squid/conf.d/listas.conf
				fi
				if [ $opcion2 == "1" ]
				then
						#Validación del nombre de la ACL para que no contenga espacios ni metacaracteres que puedan crear conflicto. Tambien valida que la ACL ya no exista.
						while true
						do
							read -p "Indique el nombre de la ACL: " nombre_acl
							comprobacion=`echo $nombre_acl | grep -Ee " |\.|\"" -v`
							comprobacion2=`cat /etc/squid/conf.d/listas.conf | cut -d " " -f2 | grep "$nombre_acl" -o`
							if [[ -z $comprobacion ]] || [[ $nombre_acl == $comprobacion2 ]]
							then
								echo "Nombre no válido"
							else
								break
							fi
						done
						while true
                                                do
							#Validación de tipo de ACL
                                                        read -p "Indique el tipo de la ACL: " tipo_acl
                                                        if [[ $tipo_acl != "src" ]] && [[ $tipo_acl != "url_regex" ]] && [[ $tipo_acl != "time" ]] && [[ $tipo_acl != "arp" ]]
                                                        then
                                                                echo "Tipo de ACL no válido"
                                                        else
								if [[ $tipo_acl == "src" ]] || [[ $tipo_acl == "url_regex" ]] || [[ $tipo_acl == "arp" ]]
								then
									while true
									do
										#Validación del fichero indicado, asi como los errores que contiene para las ACL que se quieran crear. 
										read -p "Indique el fichero que contenga los datos para estas ACL: " ficheroo
										if ! [ -f $ficheroo ]
 							                        then 
										echo "El fichero indicado no existe"
										else 
											#En el caso del tipo SRC, se valida que en el archivo introducido existan IPs
											if [ $tipo_acl == "src" ]
											then
												errores=`cat $ficheroo | grep -Ee ^'([0-1]{0,1}[0-9]{0,1}[0-9]{1}|[2]{1}[0-4]{1}[0-9]{1}[2]{1}[5]{1}[0-2]{1})\.([0-1]{0,1}[0-9]{0,1}[0-9]{1}|[2]{1}[0-4]{1}[0-9]{1}[2]{1}[5]{1}[0-2]{1})\.([0-1]{0,1}[0-9]{0,1}[0-9]{1}|[2]{1}[0-4]{1}[0-9]{1}[2]{1}[5]{1}[0-2]{1})\.([0-1]{0,1}[0-9]{0,1}[0-9]{1}|[2]{1}[0-4]{1}[0-9]{1}[2]{1}[5]{1}[0-2]{1})'$ | wc -c`
												if [ $errores != "0" ]
												then
												echo "El archivo de referencia indicado tiene las siguientes líneas con errores: "
												sudo cat $ficheroo | grep -Ee ^'([0-1]{0,1}[0-9]{0,1}[0-9]{1}|[2]{1}[0-4]{1}[0-9]{1}[2]{1}[5]{1}[0-2]{1})\.([0-1]{0,1}[0-9]{0,1}[0-9]{1}|[2]{1}[0-4]{1}[0-9]{1}[2]{1}[5]{1}[0-2]{1})\.([0-1]{0,1}[0-9]{0,1}[0-9]{1}|[2]{1}[0-4]{1}[0-9]{1}[2]{1}[5]{1}[0-2]{1})\.([0-1]{0,1}[0-9]{0,1}[0-9]{1}|[2]{1}[0-4]{1}[0-9]{1}[2]{1}[5]{1}[0-2]{1})'$ -v 
												fi
											fi
											#En el caso del tipo ARP, se valida que lo que exista en el archivo indicado sean direciones MAC con el formato que acepta el servicio
											if [ $tipo_acl == "arp" ]
											then
												errores=`cat $ficheroo | grep -Ee ^'([A-Za-z0-9]{2}:){5}[A-Za-z0-9]{2}'$ -v | wc -c`
												if [ $errores != "0" ]
												then
												echo "El archivo de referencia indicado tiene las siguientes líneas con errores: "
												sudo cat $ficheroo | grep -Ee ^'([A-Za-z0-9]{2}:){5}[A-Za-z0-9]{2}'$ -v
												fi
											fi
											#En caso de que se introduca url_regex, dado que las URL tienen multitud de caracteres, o palabras clave, solo se valida que no existan espacios
											if [ $tipo_acl == "url_regex" ]
											then
												errores=`cat $ficheroo | grep -Ee ' .*' | wc -c`
												if [ $errores != "0" ]
												then
												echo "El archivo de referencia indicado tiene las siguientes líneas con errores: "
												sudo cat $ficheroo | grep -Ee ' .*'
												fi
											fi
										break
										fi
									done
								acl="acl $nombre_acl $tipo_acl '$ficheroo'"
								sudo echo $acl >> /etc/squid/conf.d/listas.conf 
								#Validación de la ACL de tiempo.
								elif  [ $tipo_acl == "time" ]
								then
									while true
									do
										#En caso de ACL de tiempo, se valida que el intervalo horario sea correcto
										read -p "Indique intervalos horarios" $horarios
										verificar=`echo $horarios | grep -E ^"(|M)(|T)(|W)(|H)(|F)(|A)(|S) [1-2]{0,1}[0-9]{1}:[0-5]{1}[0-9]{1}-[1-2]{0,1}[0-9]{1}:[0-5]{1}[0-9]{1}"$ -o`
										if [ -z $verificar ]
										then
											echo "Formato horario incorrecto"
										else
											break
										fi
                                                                	done
									acl="acl $nombre_acl $tipo_acl $horarios"
									#Creación de la ACL
									echo $acl >> /etc/squid/conf.d/listas.conf
									echo "La ACL construida es: $acl"
								fi
							break
							fi
						done

				elif [ $opcion2 == "2" ]
				then
				#Eliminación de ACL. Se comprueba si existe o no, y en caso de que sí exista la elimina
					while true
                                        do
						while read y
						do
							echo "$y "
						done < /etc/squid/conf.d/listas.conf
						read -p "Indique la línea a eliminar: " acl_eliminar
                                                comprobacion=` cat /etc/squid/conf.d/listas.conf | cut -d " " -f 2 | grep -E ^"$acl_eliminar"$ -o`
						if ! [ -z $comprobacion  ]
                                                then
							sudo sed -E "/acl $acl_eliminar/d" /etc/squid/conf.d/listas.conf -i
							break
						else 
							echo "Esta ACL no existe"
                                 		fi
                                         done

				elif [ $opcion2 == "3" ]
				then
					break
				else
					echo "Opcion no contemplada"
				fi
			done
		elif [ $opcion == "4" ]
			then
			if ! [ -f "/etc/squid/conf.d/reglas.conf" ]
                                then
                                        sudo touch /etc/squid/conf.d/reglas.conf
					sudo chmod o+rw /etc/squid/conf.d/reglas.conf
                                fi
			echo "Reglas de control de acceso"
			echo "1 - Añadir regla en fila concreta"
			echo "2 - Eliminar regla"
			echo "3 - Salir"
			read -p "¿Que opcion desea ejecutar?: " opcion2
			if [ $opcion2 == "1" ]
				then
				while true
                                do
					read -p "Indique la regla a aplicar: " regla
					comprobar=`echo "$regla" | grep -E ^"http_access (deny|allow) " -o`
					if [[ -z $comprobar ]]
					then
						echo "Indique un tipo de regla correcta"
						error="error"
					else
						break
					fi
				done
				contador=3
				while true
				do
					var=`echo $regla | cut -d " " -f$contador`
					comprobacion=`sudo cat /etc/squid/conf.d/listas.conf | cut -d " " -f2 | grep "$var" -o`
					if [[ -z $comprobacion ]] && [[ -z $var ]] && [ $contador == 3 ]
					then
						echo "Indique un minimo de una ACL"
						break
					elif [[ -z $comprobacion ]] && [[ -z $var ]]
					then
						longitud=`cat /etc/squid/conf.d/reglas.conf | wc -l`
						echo $longitud
						if ! [ -f "/etc/squid/conf.d/tmp.reglas.conf" ]
                                                then
                                                        sudo touch /etc/squid/conf.d/tmp.reglas.conf
                                                        sudo chmod o+rw /etc/squid/conf.d/tmp.reglas.conf
                                                fi

						if  [[ $longitud == "0" ]]
						then
							sudo echo $regla >> /etc/squid/conf.d/reglas.conf
							sudo rm -R /etc/squid/conf.d/tmp.reglas.conf
							break

						else
						read -p "¿En que fila desea colocar la regla?" reglaa
						if [[ $reglaa -gt $longitud ]]
						then
							sudo echo $regla >> /etc/squid/conf.d/reglas.conf
                                                        sudo rm -R /etc/squid/conf.d/tmp.reglas.conf
                                                        break

						else
						contador=1
						while read y
						do
							if [[ $contador == $reglaa ]]
							then
								sudo echo $regla >> /etc/squid/conf.d/tmp.reglas.conf
							fi
							sudo echo $y >> /etc/squid/conf.d/tmp.reglas.conf
							contador=$((contador + 1))
						done < /etc/squid/conf.d/reglas.conf
						sudo rm -R /etc/squid/conf.d/reglas.conf
						sudo mv /etc/squid/conf.d/tmp.reglas.conf /etc/squid/conf.d/reglas.conf
						sudo chmod o+rw /etc/squid/conf.d/reglas.conf
						break
						fi
						fi
					fi
					#Commprueba si la ACL a aplicar verdaderamente existe.
					if ! [[ -z $var ]]
					then
						if [ -z $comprobacion ]
						then
							echo "Las ACL indicadas no son válidas"
						break
						fi
					fi
					contador=$((contador + 1))
				done
			elif [ $opcion2 == "2" ]
			then
				while true
                                do
					cat /etc/squid/conf.d/reglas.conf
					read -p "¿Que regla desea eliminar?" regla
					comprobar_regla=`cat /etc/squid/conf.d/reglas.conf | grep "$regla" -o`
					if ! [ -z $comprobar_regla  ]
                                        then
                                                   sudo sed -E "/$regla/d" /etc/squid/conf.d/reglas.conf -i
                                                   break
                                        else 
                                                   echo "Esta regla no existe"
                                        fi
                                done

			elif [ $opcion2 == "3" ]
			then
				break
			else
				echo "Opcion no contemplada"
			fi
		elif [ $opcion == "5" ]
		then
			while true
                                do
                                        read -p "¿Desea reiniciar el servicio y aplicar los cambios? (yes/no): " actualizacion
                                        if [ $actualizacion == "yes" ]
                                        then
                                                sudo systemctl restart squid &>/dev/null
                                                break
                                        elif [ $actualización == "no" ]
                                        then
                                                break
                                        else
                                                echo "Opcion no contemplada"
                                        fi
                                done
				break
		else
			echo "Opcion no contemplada"
		fi
		echo " "
	done
fi
