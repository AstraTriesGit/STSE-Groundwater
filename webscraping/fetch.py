import time

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.select import Select
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.action_chains import ActionChains

from dataprocessors import DataProcessor

def standby():
    print("Standby!")
    while True:
        pass


class DataFetcher:
    def __init__(self):
        """
        Sets all the options for the driver in this method itself. No need to duplicate things, right?
        Sets a driver field ready for work!
        """
        options = Options()
        options.add_argument("--no-sandbox")
        options.add_argument('--disable-dev-shm-usage')

        prefs = {"download.default_directory": "~/Downloads"}
        options.add_experimental_option("prefs", prefs)
        self.driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
        self.driver.get("https://indiawris.gov.in/wris/#/groundWater")

    def download_one(self):
        # wait for the entire ArcGIS application to load
        WebDriverWait(self.driver, 25).until(
            EC.frame_to_be_available_and_switch_to_it((By.CSS_SELECTOR, "iframe[src*='Groundwaterlevelnew']"))
        )

        time.sleep(25)
        # the simulated user usage
        data_download_button = WebDriverWait(self.driver, 25).until(
            EC.element_to_be_clickable((By.ID, "myBtn"))
        )
        data_download_button.click()
        report_type = WebDriverWait(self.driver, 25).until(
            EC.element_to_be_clickable((By.ID, "select_reportType"))
        )
        select_report_type = Select(report_type)
        select_report_type.select_by_value("Statewise")

        # a much more involved state selection process
        state_dropdown = WebDriverWait(self.driver, 25).until(
            EC.element_to_be_clickable((By.CLASS_NAME, "dropdown-btn"))
        )
        state_dropdown.click()

        # WebDriverWait(self.driver, 10)
        # .until(EC.element_to_be_clickable((By.XPATH,
        # "/html/body/app-root/app-groundwaterlevelnew/div[2]/div/div/div[2]/div/div/div[2]/div/div[1]/select")))

        # select state
        WebDriverWait(self.driver, 25).until(
            EC.element_to_be_clickable((By.XPATH, "/html/body/app-root/app-groundwaterlevelnew/div[2]/div/div/div[2]/div/div/div[2]/div/div[2]/div/ng-multiselect-dropdown/div/div[2]/ul[2]/li[37]"))
        ).click()
        state_dropdown.click()

        # need to add another wait because the Source refuses to set to CGWB sometimes
        time.sleep(10)

        start_date = WebDriverWait(self.driver, 25).until(
            EC.presence_of_element_located((By.ID, "startDateDiv"))
        )
        start_date.send_keys("2019-06-01")
        end_date = WebDriverWait(self.driver, 25).until(
            EC.presence_of_element_located((By.ID, "endDateDiv"))
        )
        end_date.send_keys("2019-06-30")

        standby()


        final_download_button = WebDriverWait(self.driver, 25).until(
            EC.element_to_be_clickable((By.ID, "dataDownloadforReport"))
        )
        final_download_button.click()
        while True:
            final_download_button.click()
            print('chaljaaaaaaaaaa')


        student_checkbox = WebDriverWait(self.driver, 25).until(
            EC.presence_of_element_located((By.ID, "Student"))
        )
        student_checkbox.click()
        name_input = WebDriverWait(self.driver, 20).until(
            EC.presence_of_element_located((By.ID, "nameID"))
        )
        name_input.send_keys("Tony Redgrave")
        email_input = WebDriverWait(self.driver, 20).until(
            EC.presence_of_element_located((By.ID, "emailID"))
        )
        email_input.send_keys("tonyredgrave.hunter@gmail.com")
        submit_button = WebDriverWait(self.driver, 25).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, "button.btn.btn-success"))
        )
        submit_button.click()





class CoordFetcher:
    def __init__(self):
        """
        Sets all the options for the driver in this method itself. No need to duplicate things, right?
        Sets a driver field ready for work!
        """
        options = Options()
        options.add_argument("--no-sandbox")
        options.add_argument('--disable-dev-shm-usage')

        prefs = {"download.default_directory": "~/Downloads"}
        options.add_experimental_option("prefs", prefs)
        self.driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
        self.driver.get("https://www.arcgis.com/home/webmap/viewer.html?url=https%3A%2F%2Farc.indiawris.gov.in%2Fserver%2Frest%2Fservices%2FNWIC%2FGroundwater_Stations%2FMapServer&source=sd")

    def get_coord_table(self):
        wait = WebDriverWait(self.driver, 25)

        # ArcGIS application
        wait.until(EC.frame_to_be_available_and_switch_to_it((By.XPATH, "/html/body/app-root/app-geovisualization/iframe")))
        time.sleep(5)
        # layer list
        wait.until(EC.element_to_be_clickable((By.XPATH, "/html/body/div[2]/div[2]/div[3]/div[2]/div[8]"))).click()
        # checkbox
        wait.until(EC.element_to_be_clickable((By.XPATH, "/html/body/div[2]/div[2]/div[1]/div[8]/div[2]/div/div/div/div[3]/div/table/tbody[1]/tr[79]/td[1]/div[2]/div"))).click()
        # dropdown menu
        # wait.until(EC.element_to_be_clickable((By.XPATH,"/html/body/div[2]/div[2]/div[1]/div[8]/div[2]/div/div/div/div[3]/div/table/tbody[1]/tr[79]/td[1]/div[1]"))).click()
        # # kebab button
        # wait.until(EC.presence_of_element_located((By.XPATH, "/html/body/div[2]/div[2]/div[1]/div[8]/div[2]/div/div/div/div[3]/div/table/tbody[1]/tr[80]/td/table/tr[1]/td[3]/div/div[2]/div[4]"))).click()
        # # view in attribute table
        # wait.until(EC.element_to_be_clickable((By.XPATH, "/html/body/div[2]/div[2]/div[1]/div[8]/div[2]/div/div/div/div[3]/div/table/tbody[1]/tr[80]/td/table/tr[1]/td[3]/div/div[2]/div[5]/div[3]"))).click()

        # open attribute table
        time.sleep(3)
        # self.driver.find_element(By.TAG_NAME, "body").click()

        actions = ActionChains(self.driver)
        actions.move_by_offset(0, 0).click().perform()
        wait.until(EC.element_to_be_clickable((By.XPATH, "/html/body/div[2]/div[2]/div[3]/div[1]"))).click()
        time.sleep(20)

    def take_two(self):
        wait = WebDriverWait(self.driver, 25)
        # Groundwater Stations
        wait.until(EC.element_to_be_clickable((By.XPATH, "/html/body/div[1]/div[1]/div[3]/div[3]/div/div/div[3]/div[2]/div/div[1]/div[2]/div[1]/div[1]/table/tbody/tr/td[4]/span"))).click()
        time.sleep(2)
        wait.until(EC.element_to_be_clickable((By.XPATH,
                                               "/html/body/div[1]/div[1]/div[3]/div[3]/div/div/div[3]/div[2]/div/div[1]/div[2]/div[1]/div[1]/table/tbody/tr/td[4]/span"))).click()
        # Groundwater Station
        wait.until(EC.element_to_be_clickable((By.XPATH, "/html/body/div[1]/div[1]/div[3]/div[3]/div/div/div[3]/div[2]/div/div[1]/div[2]/div[1]/div[2]/div[1]/table/tbody/tr/td[3]/span"))).click()
        # Show Table
        wait.until(EC.element_to_be_clickable((By.XPATH, "/html/body/div[1]/div[1]/div[3]/div[3]/div/div/div[3]/div[2]/div/div[1]/div[2]/div[1]/div[2]/div[1]/div[1]/div[2]/span"))).click()

        # Now that we have the table, let the magic begin...
        table = WebDriverWait(self.driver, 25).until(
            EC.element_to_be_clickable((By.XPATH, "/html/body/div[1]/div[1]/div[3]/div[5]/div[4]/div[1]/div/div/div/div[1]/div/div/div[2]/div/div[2]/div"))
        )
        rows = WebDriverWait(self.driver, 10).until(
            EC.presence_of_all_elements_located((By.CSS_SELECTOR, "div[role='row']"))
        )
        print(rows)

        processor = DataProcessor()
        rows = table.find_elements("css selector", "div[role='row']")
        print(rows)

        for row in rows:
            row_data = processor.extract_row_data(row)
            print(row_data)
            break

        time.sleep(25)
