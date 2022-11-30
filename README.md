# comms-analyzer-toolbox

Docker image that provides a simplified OSINT toolset for the import and analysis of communications content from email [MBOX](https://en.wikipedia.org/wiki/Mbox) files, and other CSV data (such as text messages) using Elasticsearch and Kibana. This provides a single command that launches a full OSINT analytical software stack as well as imports all of your communications into it, ready for analysis w/ Kibana and ElasticSearch.

* [Summary](#summary)
* [Docker setup](#dockersetup)
* Importing email from MBOX files
  * [MBOX import summary](#mboxsummary)
  * [Example: Export from Gmail](#gmailexample)
  * [Example: Import emails from MBOX export file](#runningmbox)
  * [MBOX import options](#mboxoptions)
  * [Troubleshooting](#mboxwarn)
* Importing data from CSV files
  * [CSV import summary](#csvsummary)
  * [Example: Export text messages from Iphone](#iphoneexample)
  * [Example: Import text messages from CSV data file](#runningcsv)
  * [CSV import options](#csvoptions)
* [Analyze previously imported data](#analyzeonly)
* [Expected warnings](#warn)
* [Help/Resources](#help)
* [Security/Privacy](#security)

## <a id="summary"></a> Summary

This project manages a Dockerfile to produce an image that when run starts both ElasticSearch and Kibana and then optionally imports communications data using the the following tools bundled within the container:

**IMPORTANT** *the links below are **FORKS** of the original projects due to outstanding issues w/ the original projects that were not fixed at the time of this projects development*

* [elasticsearch-gmail](https://github.com/bitsofinfo/elasticsearch-gmail) python scripts which import email data from an MBOX file. (See [this link](https://github.com/oliver006/elasticsearch-gmail/pulls?q=is%3Apr+author%3Abitsofinfo+is%3Aclosed) for issues this fork addresses)
* [csv2es](https://github.com/bitsofinfo/csv2es) python scripts which can import any data from an CSV file. (See [this link](https://github.com/rholder/csv2es/pulls/bitsofinfo) for issues this fork addresses)

From there... well, you can analyze and visualize practically anything about your communications. Enjoy.

![Diag1](/docs/diag1.png "Diagram1")

![Diag2](/docs/diag2.png "Diagram2")

## <a id="dockersetup"></a>Docker setup

Before running the example below, you need [Docker](https://www.docker.com/get-docker) installed.

* [Docker for Mac](https://store.docker.com/editions/community/docker-ce-desktop-mac)
* [Docker Toolbox for Windows 10+ home or earlier versions](https://www.docker.com/products/docker-toolbox)
* [Docker for Windows 10+ pro, enterprise, hyper-v capable](https://www.docker.com/docker-windows)

**Windows Note**: When you `git clone` this project on Windows prior to building be sure to add the git clone flag `--config core.autocrlf=input`. Example `git clone https://github.com/bitsofinfo/comms-analyzer-toolbox.git --config core.autocrlf=input`. [read more here](http://willi.am/blog/2016/08/11/docker-for-windows-dealing-with-windows-line-endings/)

Once Docker is installed bring up a command line shell and type the following to build the docker image for the toolbox:

```
docker build -t comms-analyzer-toolbox .
```

**Docker toolbox for Windows notes**

The `default` docker machine VM created is likely to underpowered to run this out of the box. You will need to do the following to increase the CPU and memory of the local virtual-box machine

1. Bring up a "Docker Quickstart Terminal"

2. Remove the default machine: `docker-machine rm default`

3. Recreate it: `docker-machine create -d virtualbox --virtualbox-cpu-count=[N cpus] --virtualbox-memory=[XXXX megabytes] --virtualbox-disk-size=[XXXXXX] default`

**Troubleshooting error: "max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]"**

If you see this error when starting the toolbox (the error is reported from Elasticsearch) you will need do the following on the docker host the container is being launched on.

`sysctl -w vm.max_map_count=262144`

If you are using Docker Toolbox, you have to first shell into the boot2docker VM first with `docker ssh default` to run this command. Or do the following to make it permanent: https://github.com/docker/machine/issues/3859

## <a id="mboxsummary"></a>MBOX import summary

For every email message in your MBOX file, each message becomes a separate document in ElasticSearch where all email headers are indexed as individual fields and all body content indexed and stripped of html/css/js.

For example, each email imported into the index has the following fields available for searching and analysis in Kibana (plus many, many more)

* date_ts (epoch_millis timestamp in GMT/UTC)
* to
* from
* cc
* bcc
* subject
* body
* body_size

## <a id="gmailexample"></a>Example: export Gmail email to mbox file

Once Docker is available on your system, before you run `comms-analyzer-toolbox` you need to have some email to analyze in MBOX format. As an example, below is how to export email from Gmail.

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


## <a id="runningmbox"></a>Running: import emails for analysis

Before running the example below, you need [Docker](#dockersetup) installed.

Bring up a terminal or command prompt on your computer and run the following, before doing so, you need to replace `PATH/TO/YOUR/email.mbox` and `PATH/TO/ELASTICSEARCH_DATA_DIR` below with the proper paths on your local system as appropriate.

*Note: if using Docker Toolbox for Windows*: All of the mounted volumes below should live somewhere under your home directory under `c:\Users\[your username]\...` due to permissions issues.

```
docker run --rm -ti \
   --ulimit nofile=65536:65536 \
  -v PATH/TO/YOUR/my-email.mbox:/toolbox/email.mbox \
  -v PATH/TO/ELASTICSEARCH_DATA_DIR:/toolbox/elasticsearch/data \
  comms-analyzer-toolbox:latest \
  python /toolbox/elasticsearch-gmail/src/index_emails.py \
  --infile=/toolbox/email.mbox \
  --init=[True | False] \
  --index-bodies=True \
  --index-bodies-ignore-content-types=application,image \
  --index-bodies-html-parser=html5lib \
  --index-name=comm_data
```

Setting `--init=True` will delete and re-create the `comm_data` index. Setting `--init=False` will retain whatever data already exists

The console will log output of what is going on, when the system is booted up you can bring up a web browser on your desktop and go to *http://localhost:5601* to start using Kibana to analyze your data. *Note: if running docker toolbox; 'localhost' might not work, execute a `docker-machine env default` to determine your docker hosts IP address, then go to http://[machine-ip]:5601"*

On the first screen that says `Configure an index pattern`, in the field labeled `Index name or pattern` you type `comm_data` you will then see the `date_ts` field auto-selected, then hit the `Create` button. From there Kibana is ready to use!

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

## <a id="mboxoptions"></a>Toolbox MBOX import options

When running the `comms-analyzer-toolbox` image, one of the arguments is to invoke the [elasticsearch-gmail](https://github.com/bitsofinfo/elasticsearch-gmail) script which takes the following arguments. You can adjust the `docker run` command above to pass the following flags as you please:

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
                                   HTML/CSS/JS etc. Adds fields: 'body',
                                   'body_size' and 'body_filenames' for any
                                   multi-part attachments (default False)
  --index-bodies-html-parser       The BeautifulSoup parser to use for
                                   HTML/CSS/JS stripping. Valid values
                                   'html.parser', 'lxml', 'html5lib' (default
                                   html.parser)
  --index-bodies-ignore-content-types
                                   If --index-bodies enabled, optional list of
                                   body 'Content-Type' header keywords to match
                                   to ignore and skip decoding/indexing. For
                                   all ignored parts, the content type will be
                                   added to the indexed field
                                   'body_ignored_content_types' (default
                                   application,image)
  --index-name                     Name of the index to store your messages
                                   (default gmail)
  --infile                         The mbox input file

  --init                           Force deleting and re-initializing the
                                   Elasticsearch index (default False)
  --num-of-shards                  Number of shards for ES index (default 2)

  --skip                           Number of messages to skip from the mbox
                                   file (default 0)

```

## <a id="mboxwarn"></a> MBOX import expected warnings

When importing MBOX email data, in the log output you may see warnings/errors like the following.

They are expected and ok, they are simply warnings about some special characters that are not able to be decoded etc.

```
...
/usr/lib/python2.7/site-packages/bs4/__init__.py:282: UserWarning: "https://someurl.com/whatever" looks like a URL. Beautiful Soup is not an HTTP client. You should probably use an HTTP client like requests to get the document behind the URL, and feed that document to Beautiful Soup.
  ' that document to Beautiful Soup.' % decoded_markup
[W 170825 18:41:56 dammit:381] Some characters could not be decoded, and were replaced with REPLACEMENT CHARACTER.
[W 170825 18:41:56 dammit:381] Some characters could not be decoded, and were replaced with REPLACEMENT CHARACTER.
...
```


## <a id="csvsummary"></a>CSV import summary

The CSV import tool `csv2es` embedded in the toolbox can import ANY CSV file, not just this example format below.

For every row of data in a CSV file, each row becomes a separate document in ElasticSearch where all CSV columns are indexed as individual fields

For example, each line in the CSV data file below (text messages from an iphone) imported into the index has the following fields available for searching and analysis in Kibana

```
"Name","Address","date_ts","Message","Attachment","iMessage"
"Me","+1 555-555-5555","7/17/2016 9:21:39 AM","How are you doing?","","True"
"Joe Smith","+1 555-444-4444","7/17/2016 9:38:56 AM","Pretty good you?","","True"
"Me","+1 555-555-5555","7/17/2016 9:39:02 AM","Great!","","True"
....
```

* date_ts (epoch_millis timestamp in GMT/UTC)
* name
* address
* message
* attachment
* imessage

*The above text messages export CSV is just an example.* The `csv2es` tool that is bundled with the toolbox *can import ANY data set you want* not just the example format above.

# <a id="iphoneexample"></a>Example: Export text messages from Iphone

Once Docker is available on your system, before you run `comms-analyzer-toolbox` you need to have some data to analyze in CSV format. As an example, below is how to export text messages from an iphone to a CSV file.

1. Export iphone messages using [iExplorer for mac or windows](https://macroplant.com/iexplorer/tutorials/how-to-transfer-and-backup-sms-and-imessages)

2. Edit the generated CSV file and change the first row's header value of `"Time"` to `"date_ts"`, save and exit.

2. Take note of the location of your *.csv* file as you will use it below when running the toolbox.

## <a id="runningcsv"></a>Running: import CSV of text messages for analysis

Before running the example below, you need [Docker](#dockersetup) installed.

This example below is specifically for a CSV data file containing text message data exported using [IExplorer](https://macroplant.com/iexplorer)

*Contents of data.csv*
```
"Name","Address","date_ts","Message","Attachment","iMessage"
"Me","+1 555-555-5555","7/17/2016 9:21:39 AM","How are you doing?","","True"
"Joe Smith","+1 555-444-4444","7/17/2016 9:38:56 AM","Pretty good you?","","True"
"Me","+1 555-555-5555","7/17/2016 9:39:02 AM","Great!","","True"
....
```

*Contents of csvdata.mapping.json*
```
{
    "dynamic": "true",
    "properties": {
        "date_ts": {"type": "date" },
        "name": {"type": "string", "index" : "not_analyzed"},
        "address": {"type": "string", "index" : "not_analyzed"},
        "imessage": {"type": "string", "index" : "not_analyzed"}
    }
}
```

Bring up a terminal or command prompt on your computer and run the following, before doing so, you need to replace `PATH/TO/YOUR/data.csv`, `PATH/TO/YOUR/csvdata.mapping.json` and `PATH/TO/ELASTICSEARCH_DATA_DIR` below with the proper paths on your local system as appropriate.

*Note: if using Docker Toolbox for Windows*: All of the mounted volumes below should live somewhere under your home directory under `c:\Users\[your username]\...` due to permissions issues.

```
docker run --rm -ti -p 5601:5601 \
  -v PATH/TO/YOUR/data.csv:/toolbox/data.csv \
  -v PATH/TO/YOUR/csvdata.mapping.json:/toolbox/csvdata.mapping.json \
  -v PATH/TO/ELASTICSEARCH_DATA_DIR:/toolbox/elasticsearch/data \
  comms-analyzer-toolbox:latest \
  python /toolbox/csv2es/csv2es.py \
    [--existing-index \]
    [--delete-index \]
	 --index-name comm_data \
	 --doc-type txtmsg \
	 --mapping-file /toolbox/csvdata.mapping.json \
	 --import-file /toolbox/data.csv \
	 --delimiter ',' \
	 --csv-clean-fieldnames \
	 --csv-date-field date_ts \
	 --csv-date-field-gmt-offset -1
```

If running against a pre-existing `comm_data` index make sure to include the `--existing-index` flag only. If you want to re-create the `comm_data` index prior to import, include the `--delete-index` flag only.

The console will log output of what is going on, when the system is booted up you can bring up a web browser on your desktop and go to *http://localhost:5601* to start using Kibana to analyze your data. *Note: if running docker toolbox; 'localhost' might not work, execute a `docker-machine env default` to determine your docker hosts IP address, then go to http://[machine-ip]:5601"*

On the first screen that says `Configure an index pattern`, in the field labeled `Index name or pattern` you type `comm_data` you will then see the `date_ts` field auto-selected, then hit the `Create` button. From there Kibana is ready to use!

Launching does several things in the following order

1. Starts ElasticSearch (where your indexed CSV data is stored)
2. Starts Kibana (the user-interface to query the index)
3. Starts the CSV file importer

When then mbox importer is running you will see the following entries in the logs as the system does its work importing your mail from the mbox files

## <a id="csvoptions"></a>Toolbox CSV import options

When running the `comms-analyzer-toolbox` image, one of the arguments is to invoke the [csv2es](https://github.com/bitsofinfo/csv2es) script which takes the following arguments. You can adjust the `docker run` command above to pass the following flags as you please:

```
Usage: /toolbox/csv2es/csv2es.py [OPTIONS]

  Bulk import a delimited file into a target Elasticsearch instance. Common
  delimited files include things like CSV and TSV.

  Load a CSV file:
    csv2es --index-name potatoes --doc-type potato --import-file potatoes.csv

  For a TSV file, note the tab delimiter option
    csv2es --index-name tomatoes --doc-type tomato --import-file tomatoes.tsv --tab

  For a nifty pipe-delimited file (delimiters must be one character):
    csv2es --index-name pipes --doc-type pipe --import-file pipes.psv --delimiter '|'

Options:
  --index-name TEXT               Index name to load data into
                                  [required]
  --doc-type TEXT                 The document type (like user_records)
                                  [required]
  --import-file TEXT              File to import (or '-' for stdin)
                                  [required]
  --mapping-file TEXT             JSON mapping file for index
  --delimiter TEXT                The field delimiter to use, defaults to CSV
  --tab                           Assume tab-separated, overrides delimiter
  --host TEXT                     The Elasticsearch host
                                  (http://127.0.0.1:9200/)
  --docs-per-chunk INTEGER        The documents per chunk to upload (5000)
  --bytes-per-chunk INTEGER       The bytes per chunk to upload (100000)
  --parallel INTEGER              Parallel uploads to send at once, defaults
                                  to 1
  --delete-index                  Delete existing index if it exists
  --existing-index                Don't create index.
  --quiet                         Minimize console output
  --csv-clean-fieldnames          Strips double quotes and lower-cases all CSV
                                  header names for proper ElasticSearch
                                  fieldnames
  --csv-date-field TEXT           The CSV header name that represents a date
                                  string to parsed (via python-dateutil) into
                                  an ElasticSearch epoch_millis
  --csv-date-field-gmt-offset INTEGER
                                  The GMT offset for the csv-date-field (i.e.
                                  +/- N hours)
  --tags TEXT                     Custom static key1=val1,key2=val2 pairs to
                                  tag all entries with
  --version                       Show the version and exit.
  --help                          Show this message and exit.
```

## <a id="analyzeonly"></a>Running: analyze previously imported data

Running in this mode will just launch elasticsearch and kibana and will not import anything. It just brings up the
toolbox so you can analyze previously imported data that resides in elasticsearch.

*Note: if using Docker Toolbox for Windows*: All of the mounted volumes below should live somewhere under your home directory under `c:\Users\[your username]\...` due to permissions issues.

```
docker run --rm -ti -p 5601:5601 \
  -v PATH/TO/ELASTICSEARCH_DATA_DIR:/toolbox/elasticsearch/data \
  comms-analyzer-toolbox:latest \
  analyze-only
```

Want to control the default ElasticSearch JVM memory heap options you can do so via
a docker environment variable i.e. `-e ES_JAVA_OPTS="-Xmx1g -Xms1g"` etc.

## <a id="help"></a>Help/Resources

### Gmail
* [Exporting Gmail](https://www.lifewire.com/how-to-export-your-emails-from-gmail-as-mbox-files-1171881)
* [Gmail download  data](https://support.google.com/accounts/answer/3024190?hl=en)

### IPhone text messages
* [Exporting text messages from IPhone to CSV](https://macroplant.com/iexplorer/tutorials/how-to-transfer-and-backup-sms-and-imessages)

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


## <a id="security"></a> Security/Privacy

Using this tool is completely local to whatever machine you are running this tool on (i.e. your Docker host). In the case of running it on your laptop or desktop computer its 100% local.

Data is not uploaded or transferred anywhere.

The data does not go anywhere other than on disk locally to the Docker host this is running on.

To completely remove the data analyzed, you can `docker rm -f [container-id]` of the `comms-analyzer-toolbox` container running on your machine.

If you mounted the elasticsearch data directory via a volume on the host (i.e. `-v PATH/TO/ELASTICSEARCH_DATA_DIR:/toolbox/elasticsearch/data`) that locally directory is where all the indexed data resides locally on disk.
