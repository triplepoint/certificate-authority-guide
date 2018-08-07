# Doc Development
This is a GitHub Pages project, and the easiest strategy for local development is just cloning this repo and running the Jekyll Github Pages development Docker container on the docs directory:

``` shell
git clone git@github.com:triplepoint/certificate-authority-guide.git

cd certificate-authority-guide

docker run -it --rm -p 4000:4000 --volume="$PWD:/srv/jekyll" \
    jekyll/jekyll:pages \
    jekyll serve -s ./docs
```

You can then go to http://0.0.0.0:4000 to see the page locally rendered.  Edits to the site's files should be immediately viewable upon browser refresh.
