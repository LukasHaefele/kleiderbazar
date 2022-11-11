# Introduction

This site is written for the kleiderbasar of the CVJM Gomaringen. All personalized data etc. belongs in the .data/ folder where that gets ignored by github. All large Data files get ignored too, like labels etc.

# Documentation:

The Documentation in the code snippets is fairly clear and most functions variables carry descriptive comments so I won't go too far into detail in this readme, however I will go into how the site works from a user perspective. (PS. I'll talk about the structures that are being gitignored).

## registring:

When you register your data is being saved as an uncofirmed user. If there are no Admins yet you will have to go into the filesystem and manually move the user from unconfirmed.json to user.json. If you want to make it an admin account you can do so by switching the "admin" bool in user.json to true. 
If an admin already exists they can now see your account in their unconfirmed user window and move you to confirmed users. Once that is done you can log in and upload items.

## Generating Items:

You can upload items via the Plus button on the suppliers site you'll reach when logging in with a suppliers account. Yaou can switch between two types of items and depending on it have different fields to fill in before uploading. Once the item is uploaded you should be able to download the tag with a generated QR code and the id and commission number as well as the description you gave, if you click the download full button you get a single pdf with all tags in the right ammounts. You can also delete the item and find it in the trashcan afterwards. 
And that's pretty much all the supplier has to do.

## Admin
### Managing Accounts:

As described above an admin needs to confirm the accounts that attempted registring. All confirmed accounts are moved to the user list where you can toggle admin and register atributes to make it an admin or register account. You can also reset the passwords of other accounts (The accountholder will have to reregister with the same email address they used before to regain access with the newly picked passsword. These accounts don't have to be reconfirmed.) and delete accounts. No data is fully lost, it is just moved to another file in the directories where it can be deleted manually. 

### Managin Data:

Admins can see all data and click buttons like the payout all button which will generate the payout receipts for all users and set their revenue value to 0 again. They can also archive all data, meaning all data files are moved into the .dataarchive/ directory and get an added date in their filename. The data is retrievable only by manually returning it to the .data/ directory and removing the date from the name of the file.

### Managing Variables:

Admins have a Variable window in which they can adjust the comissionfee and donation quota for the basar. Donation quota is a fraction(decimal) and comissionfee a fixed value deducted from the revenue of a supplier. So like donation quota = 0.2 is 20% of the revenue being deducted while comissionfee = 5 means fixed 5€ are deducted. 

## Initial Setup:

The strcture in the .data/ directory is:

-/deleted.json
-/item.json
-/marked.json
-/registerTip.json
-/reset.json
-/sold.json
-/stat.json
-/tr.json
-/trashed.json
-/unc.json
-/unconfirmed.json
-/user.json

Except stat.json all files may simply be filled with an empty list "[]", stat.json will need the following structure:
'{
  "revenue":double,                             //initial revenue, usually 0
  "comissionFee":double betwee 0-1,             //initial comission fee 
  "donation":double,                            //initial donation value
  "sr":String,                                  //key for encryption check https://pub.dev/packages/encrypt (default length 32)
  "bareUserNum":int,                            //initial supplier number, usually 0
  "maximumUser":int,                            //maximum ammount of suppliers
  "maxItem":int,                                //maximum number of items a supplier can upload if isseperated is false
  "maxId":int,                                  //the maximum value the random generated userids can have
  "dLower":"yyyy-mm-dd hh:mm:ss",               //dates in between which the site is closed, lower is earlier,
  "dUpper":"yyyy-mm-dd hh:mm:ss",               //upper is later
  "isseperated":bool,                           //bool whether or not both types of item are counted seperate
  "maxes":[int, int]                            //Maximums for seperated counts
}'

To use the page you'll need to set a usable port in the bin/server.dart file as well as set the right url for the _webSocket in web/dart/websocket.dart .
Afterwards you'll have to run webdev build and rename the existing web/ directory to anything and the new build/ directory to web/. 

If you haven't activated webdev follow this documentation: https://dart.dev/tools/webdev






# Hereon after the documentation is the basic by dart generated documentation

A server app built using [Shelf](https://pub.dev/packages/shelf),
configured to enable running with [Docker](https://www.docker.com/).

This sample code handles HTTP GET requests to `/` and `/echo/<message>`

## Running the sample

### Running with the Dart SDK

You can run the example with the [Dart SDK](https://dart.dev/get-dart)
like this:

```
$ dart run bin/server.dart
Server listening on port 8080
```

And then from a second terminal:
```
$ curl http://0.0.0.0:8080
Hello, World!
$ curl http://0.0.0.0:8080/echo/I_love_Dart
I_love_Dart
```

## Running with Docker

If you have [Docker Desktop](https://www.docker.com/get-started) installed, you
can build and run with the `docker` command:

```
$ docker build . -t myserver
$ docker run -it -p 8080:8080 myserver
Server listening on port 8080
```

And then from a second terminal:
```
$ curl http://0.0.0.0:8080
Hello, World!
$ curl http://0.0.0.0:8080/echo/I_love_Dart
I_love_Dart
```

You should see the logging printed in the first terminal:
```
2021-05-06T15:47:04.620417  0:00:00.000158 GET     [200] /
2021-05-06T15:47:08.392928  0:00:00.001216 GET     [200] /echo/I_love_Dart
```
