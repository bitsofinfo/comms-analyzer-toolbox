# mbox-analyzer-toolbox

Docker image that provides a simplified toolset for the import and analysis of email content from [MBOX](https://en.wikipedia.org/wiki/Mbox) export files using Elasticsearch and Kibana. This provides a single command that launches a full analytical software stack as well as imports all of your email into it, ready for analysis w/ Kibana and ElasticSearch.

* [Summary](#summary)
* [Docker setup](#dockersetup)
* [Example: Export from Gmail](#gmailexample)
* [Running to import emails](#running)
* [Running to analyze previously imported emails](#analyzeonly)
* [Toolbox options](#options)
* [Expected warnings](#warn)
* [Help/Resources](#help)
* [Security/Privacy](#security)


## <a id="summary"></a> Summary

This project manages a Dockerfile to produce an image that when run starts both ElasticSearch and Kibana and then imports all data using the [elasticsearch-gmail](https://github.com/oliver006/elasticsearch-gmail) python scripts which import email data from an MBOX file.

For every email message in your MBOX file, each message becomes a separate document in ElasticSearch where all email headers are indexed as individual fields and all body content indexed and stripped of html/css/js.

For example, each email imported into the index has the following fields available for searching and analysis in Kibana (plus many, many more)

* date_ts (timestamp in GMT/UTC)
* to
* from
* cc
* bcc
* subject
* body
* body_size

From there... well, you can analyze and visualize practically anything about your email. Enjoy.


![Diag1](/docs/diag1.png "Diagram1")

![Diag2](/docs/diag2.png "Diagram2")



## <a id="dockersetup"></a>Docker setup

Before running the example below, you need [Docker](https://www.docker.com/get-docker) installed.

* [Docker for Mac](https://store.docker.com/editions/community/docker-ce-desktop-mac)
* [Docker Toolbox for Windows 10+ home or earlier versions](https://www.docker.com/products/docker-toolbox)
* [Docker for Windows 10+ pro, enterprise, hyper-v capable..](https://www.docker.com/docker-windows)

**Windows Note**: When you `git clone` this project on Windows prior to building be sure to add the git clone flag `--config core.autocrlf=input`. Example `git clone https://github.com/bitsofinfo/mbox-analyzer-toolbox.git --config core.autocrlf=input`. [read more here](http://willi.am/blog/2016/08/11/docker-for-windows-dealing-with-windows-line-endings/)

Once Docker is installed bring up a command line shell and type the following to build the docker image for the toolbox:

```
docker build -t mbox-analyzer-toolbox .
```

**Docker toolbox for Windows notes**

The `default` docker machine VM created is likely to underpowered to run this out of the box. You will need to do the following to increase the CPU and memory of the local virtual-box machine

1. Bring up a "Docker Quickstart Terminal"

2. Remove the default machine: `docker-machine rm default`

3. Recreate it: `docker-machine create -d virtualbox --virtualbox-cpu-count=[N cpus] --virtualbox-memory=[XXXX megabytes] --virtualbox-disk-size=[XXXXXX] default`

**Troubleshooting error: "max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]"**

If you see this error when starting the toolbox (the error is reported from Elasticsearch) you will need do the following on the docker host the container is being launched on.

`sysctl -w vm.max_map_count=262144`

If you are using Docker Toolbox, you have to first shell into the boot2docker VM first with `docker ssh default` to run this command.

## <a id="gmailexample"></a>Example: export Gmail email to mbox file

Once Docker is available on your system, before you run `mbox-analyzer-toolbox` you need to have some email to analyze in MBOX format. As an example, below is how to export email from Gmail.

1. Login to your gmail account with a web-browser on a computer

2. Go to: https://takeout.google.com/settings/takeout

3. On the screen that says **"Download your data"**, under the section **"Select data to include"** click on the **"Select None"** button. This will grey-out all the **"Products"** listed below it

4. Now scroll down and find the greyed out section labeled **"Mail"** and click on the **X** checkbox on the right hand side. It will now turn green indicating this data will be prepared for you to download.

5. Scroll down and click on the blue **"Next"** button

6. Leave the **"Customize archive format"** settings as-is and hit the **"Create Archive"** button

7. This will now take you to a **"We're preparing your archive."** screen. This might take a few hours depending on the size of all the email you have.

8. You will receive an email from google when the archive is ready to download. When you get it, download the zip file to your local computer's hard drive, it will be named something like `takeout-[YYYMMMDDD..].zip`

9. Once save to your hard drive, you will want to unzip the file, once unzipped all of your exported mail from Gmail will live in an **mbox** export file in the `Takeout/Mail/` folder and the filename with all your mail is in: `All mail Including Spam and Trash.mbox`

10. You should rename this file to something simpler like `my-email.mbox`

11. Take note of the location of your *.mbox* file as you will use it below when running the toolbox.

## <a id="running"></a>Running: import emails for analysis

Before running the example below, you need [Docker](#dockersetup) installed.

Bring up a terminal or command prompt on your computer and run the following, before doing so, you need to replace `PATH/TO/YOUR/email.mbox` and `PATH/TO/ELASTICSEARCH_DATA_DIR` below with the proper paths on your local system as appropriate.

```
docker run --rm -ti -p 5601:5601 \
  -v PATH/TO/YOUR/my-email.mbox:/toolbox/email.mbox \
  -v PATH/TO/ELASTICSEARCH_DATA_DIR:/toolbox/elasticsearch-5.5.2/data \
  mbox-analyzer-toolbox:latest \
  python /toolbox/elasticsearch-gmail/src/index_emails.py \
  --infile=/toolbox/email.mbox \
  --init=True \
  --index-bodies=True \
  --index-name=mbox
```

The console will log output of what is going on, when the system is booted up you can bring up a web browser on your desktop and go to *http://localhost:5601* to start using Kibana to analyze your data. *Note: if running docker toolbox; 'localhost' might not work, execute a `docker-machine env default` to determine your docker hosts IP address, then go to http://[machine-ip]:5601"*

On the first screen that says `Configure an index pattern`, in the field labeled `Index name or pattern` you type `mbox` you will then see the `date_ts` field auto-selected, then hit the `Create` button. From there Kibana is ready to use!

Launching does several things in the following order

1. Starts ElasticSearch (where your indexed emails are stored)
2. Starts Kibana (the user-interface to query the index)
3. Starts the mbox importer

When then mbox importer is running you will see the following entries in the logs as the system does its work importing your mail from the mbox files

```
...
[I 170825 18:46:53 index_emails:96] Upload: OK - upload took:  467ms, total messages uploaded:   1000
[I 170825 18:48:23 index_emails:96] Upload: OK - upload took:  287ms, total messages uploaded:   2000
...
```

## <a id="analyzeonly"></a>Running: analyze previously imported emails

Running in this mode will just launch elasticsearch and kibana and will not import anything. It just brings up the
toolbox so you can analyze previously imported data that resides in elasticsearch.

```
docker run --rm -ti -p 5601:5601 \
  -v PATH/TO/YOUR/my-email.mbox:/toolbox/email.mbox \
  -v PATH/TO/ELASTICSEARCH_DATA_DIR:/toolbox/elasticsearch-5.5.2/data \
  mbox-analyzer-toolbox:latest \
  analyze-only
```


## <a id="options"></a>Toolbox options

At the core of the `mbox-analyzer-toolbox` image, is the [elasticsearch-gmail](https://github.com/oliver006/elasticsearch-gmail) script which takes the following arguments. You can adjust the `docker run` command above to pass the following flags as you please:

```
Usage: /toolbox/elasticsearch-gmail/src/index_emails.py [OPTIONS]

Options:

  --help                           show this help information

/toolbox/elasticsearch-gmail/src/index_emails.py options:

  --batch-size                     Elasticsearch bulk index batch size (default
                                   500)
  --es-url                         URL of your Elasticsearch node (default
                                   http://localhost:9200)
  --index-bodies                   Will index all body content, stripped of
                                   HTML/CSS/JS etc. Adds fields: 'body' and
                                   'body_size' (default False)
  --index-name                     Name of the index to store your messages
                                   (default gmail)
  --infile                         The mbox input file

  --init                           Force deleting and re-initializing the
                                   Elasticsearch index (default False)
  --num-of-shards                  Number of shards for ES index (default 2)

  --skip                           Number of messages to skip from the mbox
                                   file (default 0)

```

## <a id="help"></a>Help/Resources


### Gmail
* [Exporting Gmail](https://www.lifewire.com/how-to-export-your-emails-from-gmail-as-mbox-files-1171881)
* [Gmail download  data](https://support.google.com/accounts/answer/3024190?hl=en)

### Hotmail/Outlook

For hotmail/outlook, you need to export to PST, and then as a second step convert to MBOX

* https://support.microsoft.com/en-us/help/980534/export-windows-live-mail-email--contacts--and-calendar-data-to-outlook
* https://gallery.technet.microsoft.com/Convert-PST-to-MBOX-25f4bb0e
* http://www.hotmail.googleapps--backup.com/pst
* https://steemit.com/hotmail/@ariyantoooo/how-to-export-hotmail-to-pst
* http://www.techhit.com/outlook/convert_outlook_mbox.html
* https://gallery.technet.microsoft.com/office/PST-to-MBOX-Converter-to-e5ae03ae

### Kibana, graphs, searching
* [Kibana 5 tutorial](https://www.youtube.com/watch?v=mMhnGjp8oOI)
* [Kibana 101](https://www.elastic.co/webinars/getting-started-kibana?baymax=default&elektra=docs&storm=top-video)
* [Kibana getting started](https://www.elastic.co/guide/en/kibana/current/getting-started.html)
* [Kibana introduction](https://www.timroes.de/2016/10/23/kibana5-introduction/)
* [Kibana logz.io tutorial](https://logz.io/blog/kibana-tutorial/)
* [Kibana search syntax](https://www.elastic.co/guide/en/kibana/current/search.html)

## <a id="warn"></a> Expected warnings

In the log output you may see warnings/errors like the following.

They are expected and ok, they are simply warnings about some special characters that are not able to be decoded etc.

```
...
/usr/lib/python2.7/site-packages/bs4/__init__.py:282: UserWarning: "https://someurl.com/whatever" looks like a URL. Beautiful Soup is not an HTTP client. You should probably use an HTTP client like requests to get the document behind the URL, and feed that document to Beautiful Soup.
  ' that document to Beautiful Soup.' % decoded_markup
[W 170825 18:41:56 dammit:381] Some characters could not be decoded, and were replaced with REPLACEMENT CHARACTER.
[W 170825 18:41:56 dammit:381] Some characters could not be decoded, and were replaced with REPLACEMENT CHARACTER.
...
```

## <a id="security"></a> Security/Privacy

Using this tool is completely local to whatever machine you are running this tool on (i.e. your Docker host). In the case of running it on your laptop or desktop computer its 100% local.

Data is not uploaded or transferred anywhere.

The data does not go anywhere other than on disk locally to the Docker host this is running on.

To completely remove the data analyzed, you can `docker rm -f [container-id]` of the `mbox-analyzer-toolbox` container running on your machine.

If you mounted the elasticsearch data directory via a volume on the host (i.e. `-v PATH/TO/ELASTICSEARCH_DATA_DIR:/toolbox/elasticsearch-5.5.2/data`) that locally directory is where all the indexed data resides locally on disk.
