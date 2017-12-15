install.packages("httr")
install.packages("jsonlite")
install.packages("RODBC")


require("httr")
require("jsonlite")
library(RODBC)
#To make the capitalize the first letter of the vector(TOOLS LIBRARY) 
library(tools)
library(lubridate)

base <- "https://api.intrinio.com/"
endpoint <- "prices"
stock <- "AAPL"

call1 <- paste(base,endpoint,"?","ticker","=", stock,sep="") 
get_prices <- GET(call1, authenticate(rstudioapi::askForPassword("Username"),rstudioapi::askForPassword("API Password"), type = "basic"))
get_price_content<- content(get_prices, as = "text", encoding = "UTF-8") 
get_price_json <- fromJSON(get_price_content, flatten = TRUE)
get_prices_df<- as.data.frame(get_price_json)
pages<- get_price_json$total_pages


for (i in 2:pages) {
  call_2 <- paste(base,endpoint,"?","ticker","=", stock,"&","page_number=", i, sep="")
  get_prices_2 <- GET(call_2, authenticate(username,password, type = "basic"))
  get_prices_text_2 <- content(get_prices_2, as = "text",encoding = "UTF-8")
  get_prices_json_2 <- fromJSON(get_prices_text_2, flatten = TRUE)
  get_prices_df_2 <- as.data.frame(get_prices_json_2)
  get_prices_df <- rbind(get_prices_df, get_prices_df_2)
}

View(get_prices_df)
get_prices_df<- get_prices_df[,1:13]

names(get_prices_df)<- substring(names(get_prices_df[,1:13]),6)
#Change df to chara for capitalisation 

character_vector<- c(names(get_prices_df))
names(get_prices_df)<- toTitleCase(character_vector)


get_prices_df$Date <- as.Date(get_prices_df$Date)
get_prices_df$Year <- as.integer(format(get_prices_df$Date,"%Y"))
get_prices_df$Month <-as.integer(format(get_prices_df$Date,"%m"))
get_prices_df$Day<-day(get_prices_df$Date)
get_prices_df$Weekday<- as.integer(wday(get_prices_df$Date , label=TRUE))



# names(get_prices_df)[14:17]<- c("Year","Months","Day","WeekDays") 


####################################################
#DB Connection

library(DBI)

con <- DBI::dbConnect(odbc::odbc(),
                      Driver   = "SQL Server",
                      Server   = "192.168.3.38",
                      Database = "Web scraping Database",
                      UID      = rstudioapi::askForPassword("Database user"),
                      PWD      = rstudioapi::askForPassword("Database password"),
                      Port     = 1433)


ifelse(dbExistsTable(con, "Flights"),dbRemoveTable(con, "Flights"),
       dbWriteTable(con, name = "Flights", value = get_prices_df, row.names = FALSE))

View(get_prices_df)

# Write the data frame to the database
dbWriteTable(con, name = "temp_tickers", value = tickers, row.names = FALSE)
# dbWriteTable(con,"Flights",get_prices_df)


write.csv(get_prices_df, file = "Apple Stock Price.csv", row.names = FALSE)

#### Fetch data from SQL DB
res <- dbSendQuery(con, "SELECT * FROM Flights  WHERE Ex_dividend='0'")
dbClearResult(res)
a<-dbFetch(res)
View(a)

plot(get_prices_df$Date,get_prices_df$Adj_volume,main ="Date VS Adjusted Volume", xlab="Date", ylab = "Adjusted Volume", pch = 19)
