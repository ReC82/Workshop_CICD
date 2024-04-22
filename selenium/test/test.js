const {By, Key, Builder} = require("selenium-webdriver");
require("chromedriver");

async function test_case() {
    let driver = await new Builder().forBrowser("chrome").build();

    await driver.get("https://www.bing.com")
    try {
        driver =await new Builder().forBrowser("chrome").build();

        await driver.findElement(By.name("q")).sendKeys("Hello", Key.RETURN);

        console.log("Open Bing");
        await driver.sleep(10000);
        const searchInput = await driver.findElement(By.name("q"));
        await driver.quit();
        await searchInput.sendKeys("Hello", Key.RETURN);
        console.log("Input entered")
        await driver.sleep(10000);
    }
    catch (error)
    {
        console.error("ERROR : ", error);
    }
    finally
    {
        if(driver){
            await driver.quit();
            console.log("END");
        }        
    }
}

test_case();