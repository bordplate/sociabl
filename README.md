# What is this?
This is a generic social network built on the Vapor Framework for Swift and MySQL. It's goal is to be some sort of microblogging where people can follow each other. 

# Why? 
I used it in a workshop for teaching iOS development. And it's fun to just make stuff.

# Setup
You don't need much to make this work. In theory you should only need the Swift compiler and an instance of MySQL running. The Swift compiler should download all necessary packages with the package manager. I'm not too keen on pushing my MySQL-config to Git though, so you need to create `Config/secrets/mysql.json` and have it look somewhat like this:
```
{
    "host": "127.0.0.1",
    "user": "totallynotroot",
    "password": "neatpassword",
    "database": "sociabl",
    "port": "3306",
    "encoding": "utf8"
}
```
