# #Install dependencies
# install.packages("curl")
# install.packages("httr")
# 
# #Load required libraries
library(curl)
library(httr)
library(dplyr)
library(stringr)

setwd("C:/Users/Jaime/Documents/Marketing analytics")

#This loads a set of all prospects with ALL fields (BIG!)
# p <- read.csv("pardotprospects_27092023.csv") 

#Take user input for filepath
path<-readline(prompt="Input the absolute path of the input file with prospects and no persona. Remove leading and trailing quotes ")

#This loads a set ofprospects with no Persona or Persona = OTHER but non-empty job title
p <- read.csv(path)
# p <- read.csv("input test.csv")

#Filter out Aiveners and test emails
nonaiven <- filter(p, !str_detect(p$Email, "@aiven"))
nonaiven <- filter(nonaiven, !str_detect(nonaiven$Email, "test")) 


#Using the existing function to query GPT-3 and receive responses inside R
source("ask_chatgpt.R")

# source("ask_chatgpt_system.R")


#Load the previously exported and cleaned prospects into a data frame
nonaiven_df <- data.frame(nonaiven)

#Remove the ones that do not have job titles
nonaiven_withjobtitles<-filter(nonaiven_df,Job.Title!="")

#Seed value to start enrichment
seed <- 1

#Define the chunk size i.e. number of prospects being enriched at a time
#Be careful with rate limits!
chunk <- 150


#Calculate how many complete chunks can be run

#Define the total number of prospects to enrich
total_population <- dim(nonaiven_withjobtitles)[1]

#Define the total number of prospects to enrich
population_to_enrich <- floor(total_population/chunk)*chunk
leftover <- total_population - population_to_enrich

# print (paste(population_to_enrich,"prospects will be enriched in the main loop"))
# print (paste(leftover,"prospects will be enriched outside the loop"))

# population_to_enrich <- 1500


#Create a new result table
result <- ""



# #Wipe seed and loop control variables
# rm(i)
# rm(j)
# rm(k)



#Set high-water mark to zero
hwm <- seed


# definition <-"You are a world-class business analyst with a strong machine learning capability who understands multiple languages. You analyze job titles and understand the responsibility and mandate of the person carrying that title.
# You understand that ther are four types of personas in our target.
# - Executive: Hold the highest strategic roles in a company. Responsible for the creation of products/services that support the company’s strategy and vision and meet the customer needs. In charge of the cloud and open source strategy of the company. Their titles often contain Chief or Officer, also abbreviated as three-letter acronyms like CEO, CTO, etc.
# 
# - IT Manager: Make decisions on platform and infrastructure, have budget control and manage a team. They drives cloud migration, IT modernization and transformation efforts. Responsible for automated platform solutions for internal teams. Typical titles include Head/Director/Manager of Cloud, Infrastructure or Engineering.
# 
# - Architect: Specialists in cloud/ platform technologies, provide the “platform as a service” internally to application teams. They participate in business strategy development  making technology a fundamental investment tool to meet the organizations' objectives. Common titles are Cloud Architect, Platform Architect, Data Platform Manager, Principal Engineer
# 
# -Developer: Build features and applications leveraging data infrastructure. Their typical job titles include Software Engineer, Software Architect and Engineering Manager
# 
# I will next feed a number of individuals and their job titles in a 2-column table. The individual ID will be in the first column and their job title in the second.
# 
# On the basis of those definitions, please classify these individuals job titles by whether they refer to a developer, an executive, an IT decision maker, an architect or none of those. Only 1 category is possible for each job title.
# 
# Present the results in comma-separated format (columns separated by commas and rows separated by semicolons) with 4 columns: Id, Job title, classification and certainty of the classification for each value in a scale of 0 to 1: "


definition <-"You are an assistant with a strong machine learning capability who understands multiple languages including Japanese, and designed to efficiently categorize job titles into one of four distinct customer personas using a sophisticated machine learning approach.
It leverages techniques like fuzzy matching and similarity search to analyze job titles, focusing on attributes such as industry knowledge, required skills, and typical responsibilities.
You operate by receiving a 2-column table:
Prospect ID, Job title
You always return data in a comma-separated, four-column table:
Prospect ID, Job title, Persona, Certainty
The Prospect ID for each output row must be the same one that was fed as input. This is crucial.
The classification is based on the initial input only, without requiring further interaction
The output columns must be comma-separated and have no leading or trailing symbols. No context will be provided for the output.

The four available personas are:
- Executive: Hold the highest strategic roles in a company. Responsible for the creation of products/services that support the company’s strategy and vision and meet the customer needs. In charge of the cloud and open source strategy of the company. Their titles often contain Chief or Officer, also abbreviated as three-letter acronyms like CEO, CTO, etc.

- IT Manager: Makes decisions on platform and infrastructure, have budget control and manage a team. They drive cloud migration, IT modernization and transformation efforts. Responsible for automated platform solutions for internal teams. Typical titles include Head/Director/Manager of Cloud, Infrastructure or Engineering.

- Architect: Specialist in cloud/ platform technologies, provide the “platform as a service” internally to application teams. They participate in business strategy development  making technology a fundamental investment tool to meet the organizations' objectives. Common titles are Cloud Architect, Platform Architect, Data Platform Manager, Principal Engineer

- Developer: Builds features and applications leveraging data infrastructure. Their typical job titles include Software Engineer, Software Architect and Engineering Manager

Job titles that do not conform to any of these four classes (e.g. Consultant, Student, Unemployed, and many more) should be classified as Not a target.
On the basis of those definitions, please classify these individuals job titles by whether they refer to a Developer, an Executive, an IT Manager, an Architect or Not a target. Only 1 category is possible for each job title."




####Main loop####
#n defines the number of iterations, so the number of prospects enriched is num_iter*chunk

num_iter <-population_to_enrich/chunk
print (paste(num_iter,"iterations will be run"))

# num_iter<-1

for (n in 1:num_iter){

#Extract the first chunk of prospects after the i-th one
prospects_being_enriched <- nonaiven_withjobtitles[hwm:(hwm+chunk-1),]


#Extract titles and ids separately
extracted_ids <- prospects_being_enriched$Prospect.Id
extracted_titles <- prospects_being_enriched$Job.Title

#Remove commas
for (k in 1:nrow(prospects_being_enriched)) {
  extracted_titles[k] <- gsub(","," " ,extracted_titles[k], )
}


# Create an empty title table
title_table <- ""

#Create a table of job titles

for (j in 1:nrow(prospects_being_enriched)) {
  title_table <- paste(title_table, extracted_ids[j], ",", extracted_titles[j], ";")
  invisible(title_table)
  

}


#Subsequent instructions after 1st
# subs_instr <- "Now use the previous definitions of developer, data professional and tech executive to classify this next batch of job titles: "


#Format the prompt
prompt  = paste(definition,title_table)
# subs_prompt  = paste(subs_instr, title_table)

#Send the prompt to the API endpoint and receive response
answer <- ask_chatgpt(prompt)


#After the first one, we send just the title table
# subs_answer <-ask_chatgpt(subs_prompt)


#Full answer
result <- paste(result, "\n",answer)

hwm <- hwm + chunk

print(n)

# Flag to print lap numbers every 20

# if ((n%%20)==0) {
#   laps<-n
#   print(laps)
#   browser()
# }

}


###################
# Last iteration after all the major chunks

#Define chunk as the amount of leftover prospects. High water mark should be at the correct index already
chunk <- leftover

#Extract the first chunk of prospects after the i-th one
prospects_being_enriched <- nonaiven_withjobtitles[hwm:(hwm+chunk-1),]


#Extract titles and ids separately
extracted_ids <- prospects_being_enriched$Prospect.Id
extracted_titles <- prospects_being_enriched$Job.Title

#Remove commas
for (k in 1:nrow(prospects_being_enriched)) {
  extracted_titles[k] <- gsub(","," " ,extracted_titles[k], )
}


# Create an empty title table
title_table <- ""

#Create a table of job titles

for (j in 1:nrow(prospects_being_enriched)) {
  title_table <- paste(title_table, extracted_ids[j], ",", extracted_titles[j], ";")
  invisible(title_table)
}

#Format the prompt
prompt  = paste(definition,title_table)
# subs_prompt  = paste(subs_instr, title_table)

#Send the prompt to the API endpoint and receive response
answer <- ask_chatgpt(prompt)

#Full answer of leftover prospects
result <- paste(result, "\n",answer)

hwm <- hwm + chunk

#####################



#Full answer
result <- paste(result, "\n",answer)




# write.csv(answer, file='new_class6000.csv',fileEncoding = "UTF-8")

#Result normalization to prevent spurious characters
result_val <- gsub(", ","," ,result)
result_val <- gsub("; ",";" ,result_val)
result_val <- gsub(" ,","," ,result_val)
result_val <- gsub(" ;",";" ,result_val)

#Create string with current date o
date_filename <- Sys.time()
output_filename <- paste("Personas",date_filename,".txt")
output_filename <- gsub(" .txt",".txt",output_filename)

#Colons are illegal in filenames
output_filename <- gsub(":"," ",output_filename)



write.table(result_val, file=output_filename)




