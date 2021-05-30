# Link Exploring Bot 🤖

Este proyecto es solamente una pequeña función en AWS Lambda para validar los links exportados de Delicious y enviar por email los que siguen vigentes.

Dado que el otrora gran servicio [Delicious](https://del.icio.us) ahora ya está de caída :(, lo que hice fue exportar todos los links que tenía allí 
a un archivo JSON (desde el mismo Delicious, que a la fecha - Mayo del 2021 - está activo pero tiene un error de certificado que no deja acceder T-T),
e importar ese archivo JSON a una base de datos MongoDB.

Después de eso, entra en acción este pequeño lambda, escrito en Ruby, que se conecta al MongoDB, busca los links de la misma fecha (mes - día) que la actual,
intenta conectarse a cada uno de ellos, y aquellos a los que se ha podido conectar me los envía por correo para poderlos revisar nuevamente, y (eventualmente)
agregarlos a otro servicio. También marca los que se han revisado cada día y si se ha podido conectar a cada uno, para que no los vuelva a mandar en un futuro
y, eventualmente, poder filtrarlos y hacer algo con la data.

Estoy usando la gema Faraday para las peticiones HTTP; el uso es bien básico pero ha servido muy bien (b'-')b

**Complicaciones**

El driver oficial de MongoDB para Ruby requiere extensiones nativas, y para usar RubyGems con AWS Lambda hay que incluirlas junto con todo el código que se sube
(en vendor/bundle), por tanto se necesitaria compilar las extensiones nativas para el SO de AWS Lambda, que no es el mismo que actualmente estoy usando en mi
estación local 😅.  
Felizmente, se soluciona todo con Docker y una imagen ya lista:

````
docker run -it --rm -v "$PWD":/var/task lambci/lambda:build-ruby2.7 bash
````

Ese comando 👆 abre un shell en un contenedor con el mismo entorno que AWS Lambda para Ruby, montando un volumen sobre el directorio actual 
(que tiene que ser el del proyecto). Basta entonces con hacer `bundle install --path vendor/bundle` para instalar los RubyGems en el directorio vendor/bundle y 
luego zipear y subir todo a AWS Lambda.

(Fuente: https://blog.francium.tech/using-ruby-gems-with-native-extensions-on-aws-lambda-aa4a3b8862c9)

**A futuro**

Como algún día este bot terminará de revisar todos los links, eventualmente lo podremos reusar para ir revisando los links del siguiente servicio que use y 
mantenerlos siempre frescos, o incluso ofrecer la opción de buscar los que ya no funcionan en el Wayback Machine. Pero eso... para la próxima versión ;).
