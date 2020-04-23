# Intro
This repository contains the documentation and code for the [related GitHub Pages documents](https://triplepoint.github.io/certificate-authority-guide/).

# Doc Development
The `/mkdocs` folder contains a [MkDocs](https://www.mkdocs.org) project, suitable for being built and published to GitHub Pages.

Assuming you have Python and `pipenv` installed, you can launch a local development server with:
``` shell
git clone git@github.com:triplepoint/certificate-authority-guide.git

cd certificate-authority-guide
pipenv install --dev
pipenv shell

cd mkdocs
mkdocs serve
```

You can then go to http://127.0.0.1:8000 to see the page locally rendered.  Edits to the site's files should be immediately viewable upon browser refresh.

# Doc Deployment
Per MkDocs documentation, you can deploy this project with:
``` shell
mkdocs gh-deploy
```

It sometimes takes a little while for the documentation to refresh on the published site.
