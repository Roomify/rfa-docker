# rfa-docker

Creates a [Docker](https://www.docker.com/) container for demoing [Roomify for Accommodations](https://github.com/roomify/roomify).

The image contains the following -

* PHP 7.0 + Apache
* Composer
* Drush 8
* Roomify for Accommodations

The image must be linked with a database container (e.g. mysql).

## Usage

### Building with Docker compose

- Ensure you have Docker and Docker compose installed. See [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/) to get started. If you are using Mac you will probably need to install [boot2docker](http://boot2docker.io/)
- Build the Dockerfile:

```
git clone https://github.com/Roomify/rfa-docker.git
cd rfa-docker
docker-compose build
```

- Run the Docker image

```
docker-compose up -d
```

This should bring up 2 containers, 1 Drupal RfA/PHP/Apache and a second MySQL
container. Both containers should be linked and the Roomify for Accommodations database should be installed on startup.

### Building the image standalone

```
docker run --rm --name commerce_kickstart --link db:mysql capgemini/rfa-docker:latest
```

...where db:mysql matches the name and alias of your DB instance. The values from your linked DB instance will be used to complete the setup.

Once the container is up browse to port 80 on the container to view the site.
