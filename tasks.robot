*** Settings ***
Library           RPA.Browser.Selenium
Library           OperatingSystem
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.HTTP
Library           RPA.Dialogs
Library           RPA.Desktop
Library           RPA.Archive
Library           Collections
Library           RPA.Robocorp.Vault


*** Variables ***
${Order_url}                https://robotsparebinindustries.com/#/robot-order
${Orders_csvpath}           https://robotsparebinindustries.com/orders.csv
${Orders_csv}               ${CURDIR}${/}orders.csv
${PDFFolder}                ${CURDIR}${/}result
${imageFolder}              ${CURDIR}${/}image
${zip_file}                 ${PDFFolder}${/}pdf_archive.zip

***keywords***
open robot order website
    Open Available Browser   ${Order_url}
    Maximize Browser Window
    Click Button    css:button.btn.btn-dark

***keywords***
Process orders
   Download     url=${Orders_csvpath}         target_file=${Orders_csv}    overwrite=True
    ${table}=   Read table from CSV    path=${Orders_csv}
    [Return]    ${table}

***keywords***
Fill the form   
    [Arguments]             ${myrow}
    Set Local Variable      ${order_no}   ${myrow}[Order number]
    Set Local Variable      ${head}       ${myrow}[Head]
    Set Local Variable      ${body}       ${myrow}[Body]
    Set Local Variable      ${legs}       ${myrow}[Legs]
    Set Local Variable      ${address}    ${myrow}[Address]
    Set Local Variable      ${input_head}       //*[@id="head"]
    Set Local Variable      ${input_body}       body
    Set Local Variable      ${input_legs}       xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable      ${input_address}    //*[@id="address"] 
    Set Local Variable      ${preview}          //*[@id="preview"]
    Set Local Variable      ${order}            //*[@id="order"]

    Wait Until Element Is Visible   ${input_head}
    Wait Until Element Is Enabled   ${input_head}
    Select From List By Value       ${input_head}           ${head}
    Wait Until Element Is Enabled   ${input_body}
    Select Radio Button             ${input_body}           ${body}
    Wait Until Element Is Enabled   ${input_legs}
    Input Text                      ${input_legs}           ${legs}
    Wait Until Element Is Enabled   ${input_address}
    Input Text                      ${input_address}        ${address}

***keywords***
check the robots
    Set Local Variable              ${preview}          //*[@id="preview"]
    Set Local Variable              ${img_preview}      //*[@id="robot-preview-image"]
    Click Button                    ${preview}
    Wait Until Element Is Visible   ${img_preview} 
    sleep  1s

***keywords*
Submited
    Set Local Variable              ${order}       //*[@id="order"]
    Set Local Variable              ${receipt}     //*[@id="receipt"]
    Mute Run On Failure             Page Should Contain Element 
    Click button                    ${order}
    Page Should Contain Element      ${receipt}  ${order} 
    Sleep    1s 

*** Keywords ***
Take a screenshot 
    [Arguments]                     ${row}
    Capture Element Screenshot      //*[@id="robot-preview-image"]      
    ...                             ${CURDIR}${/}image${/}Order_${row}.png    
    [Return]                        ${CURDIR}${/}image${/}Order_${row}.png 

*** Keywords ***
screenshot to the PDF file
    [Arguments]         ${row}
    ${screenshot}=      Create List          ${CURDIR}${/}image${/}Order_${row}.png   
    Add Files To Pdf    ${screenshot}      ${CURDIR}${/}result${/}Order_${row}.pdf       True

*** Keywords ***
Store PDF file
    [Arguments]         ${myrow}                    
    ${pdf_file}=        Get Element Attribute      id:receipt      outerHTML
    Html To Pdf         ${pdf_file}      
    ...                 ${CURDIR}${/}result${/}Order_${myrow}.pdf
    [Return]            ${CURDIR}${/}result${/}Order_${myrow}.pdf

***keywords***
Go to order another robot
   Set Local Variable     ${order_another_robot}     //*[@id="order-another"]
   Click Button           ${order_another_robot}
   Sleep  1s 

*** Keywords ***
Create a ZIP file 
    Archive Folder With ZIP     ${PDFFolder}  ${zip_file}   recursive=True  include=*.pdf

***keywords***
annoying model
    Set Local Variable              ${btn_yep}        //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait And Click Button           ${btn_yep}

***keywords***
Log out browser
   Close Browser
   sleep  1s

***keywords***
Display the success dialog
    Add icon            Success
    Add heading         Your orders have been processed
    Add files           all orders have been processed.
    Run dialog          title=Success
    Close Browser

***keywords***
Get The User Name
    Add heading                 i am your future
    Add text input              myway   label= tell me about something?    placeholder= user give some input
    ${myarray}=                 Run dialog
    [Return]                    ${myarray.myway} 

*** Keywords ***
Get credentials
    Log To Console              Getting Secret from our Vault
    ${robotsparebin}=           Get Secret     robotsparebin    
    open available browser      https://robotsparebinindustries.com/#/
    Input Text                  id:username    ${robotsparebin}[username]
    Input Password              id:password    ${robotsparebin}[password]
    sleep  3s
    Close Browser

*** Tasks ***
Web store order   
  open robot order website
  Process orders
  ${order}=   Process orders
  FOR   ${row}   IN   @{order}
     Fill the form    ${row}
  Wait Until Keyword Succeeds     10x     1s    check the robots
  Wait Until Keyword Succeeds     10x     1s    Submited
  ${pdf}=           Store PDF file    ${row}[Order number]
  ${screenshot}=    Take a screenshot      ${row}[Order number]
  screenshot to the PDF file   ${row}[Order number]
  Go to order another robot
  annoying model
  END
  Create a ZIP file 
  Log out browser
  Display the success dialog
  Get The User Name
  Get credentials
