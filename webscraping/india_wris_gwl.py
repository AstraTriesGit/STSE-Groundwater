import time

from selenium import webdriver
from selenium.webdriver import ActionChains
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select
from selenium.webdriver.support.wait import WebDriverWait
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup

from dataclasses import dataclass

@dataclass
class GwlReading:
    station_name: str
    station_code: str
    state: str
    district: str
    basin: str
    sub_basin: str
    timestamp: str
    data_value: str


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

        self.gwl_tuples = list()


    def select_state(self):
        WebDriverWait(self.driver, 60).until(
            EC.frame_to_be_available_and_switch_to_it((By.CSS_SELECTOR, "iframe[src*='Groundwaterlevelnew']"))
        )

        # new timeouts because the website fell off further
        # wait for the entire ArcGIS application to load
        # even longer timeout because either the site sucks or my wi-fi does
        # might be both, but my bet is on the fucking government website
        # so even 120 was not enough. Lovely.
        loader = "/html/body/app-root/app-groundwaterlevelnew/div[1]/div[1]"
        WebDriverWait(self.driver, 300).until(
            EC.invisibility_of_element_located((By.XPATH, loader))
        )

        # state dropdown
        state_dropdown = Select(WebDriverWait(self.driver, 60).until(
            EC.element_to_be_clickable((By.XPATH,
                                        "/html/body/app-root/app-groundwaterlevelnew/div[1]/nav/div[2]/div[1]/div/div[1]/div[3]/div[1]/select"))
        ))

        state_list = state_dropdown.options
        state_list = [BeautifulSoup(option.get_attribute("outerHTML"), 'html.parser').string for option in state_list]
        # remove default "Select"
        state_list.pop(0)

        state_dropdown.select_by_visible_text("Andhra Pradesh")
        self.select_district()

    def select_district_right(self):

        pass

    def select_district(self):
        # now wait for the app to load relevant state/UT data
        loader = "body > app-root > app-groundwaterlevelnew > div.wrapper > div.loader"
        WebDriverWait(self.driver, 120).until(
            EC.invisibility_of_element_located((By.CSS_SELECTOR, loader))
        )

        district_dropdown = Select(WebDriverWait(self.driver, 60).until(
            EC.element_to_be_clickable((By.XPATH,
                                        "/html/body/app-root/app-groundwaterlevelnew/div[1]/nav/div[2]/div[1]/div/div[1]/div[3]/div[2]/select"))
        ))
        district_list = district_dropdown.options
        district_list = [BeautifulSoup(option.get_attribute("outerHTML"), 'html.parser').string for option in district_list]
        district_list.pop(0)

        district_dropdown.select_by_visible_text(district_list[0])
        self.select_station()

    def select_station(self):
        loader = "body > app-root > app-groundwaterlevelnew > div.wrapper > div.loader"
        WebDriverWait(self.driver, 300).until(
            EC.invisibility_of_element_located((By.CSS_SELECTOR, loader))
        )

        # only 5 at a time
        station_table = WebDriverWait(self.driver, 60).until(
            EC.presence_of_element_located((By.ID, "gwl_stateWiseTable"))
        )

        first_row = "/html/body/app-root/app-groundwaterlevelnew/div[1]/div[2]/div/div/div[2]/div[7]/div/div/table/tbody/tr[1]"
        first_row_button = "/html/body/app-root/app-groundwaterlevelnew/div[1]/div[2]/div/div/div[2]/div[7]/div/div/table/tbody/tr[1]/td[1]"
        # need to find the buttons for each available district
        current_station_html = BeautifulSoup(station_table.get_attribute("outerHTML"), 'html.parser')
        station_rows = current_station_html.tbody.find_all("tr")
        print(station_rows)
        WebDriverWait(self.driver, 60).until(
            EC.element_to_be_clickable((By.XPATH, first_row_button))
        ).click()

        self.process_station_data()

    def process_station_data(self):
        # info table
        info_table_xpath = "/html/body/app-root/app-groundwaterlevelnew/div[1]/div[2]/div/div/div[2]/div[5]/div/table"
        info_table = WebDriverWait(self.driver, 180).until(
            EC.presence_of_element_located((By.XPATH, info_table_xpath))
        )
        info_rows = (BeautifulSoup(info_table.get_attribute("outerHTML"), 'html.parser')
                     .tbody.find_all("tr"))
        # drop row name, keep the data
        fields = [row.find_all("td")[1].text for row in info_rows]

        # take two - use the interactable button to load the entire table
        graph_menu_xpath = "/html/body/app-root/app-groundwaterlevelnew/div[1]/div[2]/div/div/div[2]/div[4]/div[1]/div[3]/div[2]/div[3]/button"
        # graph_menu_selector = "#highcharts-1cm0qgw-488 > div.highcharts-a11y-proxy-container-after > div.highcharts-a11y-proxy-group.highcharts-a11y-proxy-group-chartMenu"

        # when the above finally loads, it might load the graph for the district and not for the measuring station.
        # Both the plots visually have the same elements
        # best I can do is arbitrary timer to ensure the plot refreshes for the station
        time.sleep(90) # another slowdown to scraper performance...
        graph_menu = WebDriverWait(self.driver, 120).until(
            EC.element_to_be_clickable((By.XPATH, graph_menu_xpath))
        )
        graph_menu.click()

        show_data_table = self.driver.find_element(By.XPATH, "//li[text()='View data table']")
        self.driver.execute_script("arguments[0].click();", show_data_table)

        reading_table_xpath = "/html/body/app-root/app-groundwaterlevelnew/div[1]/div[2]/div/div/div[2]/div[4]/div[2]/table/tbody"
        reading_table = WebDriverWait(self.driver, 60).until(
            EC.presence_of_element_located((By.XPATH, reading_table_xpath))
        )
        reading_table = BeautifulSoup(reading_table.get_attribute("outerHTML"), 'html.parser')
        reading_rows = reading_table.tbody.find_all("tr")
        for row in reading_rows:
            timestamp = row.th.text
            data_value = row.td.text
            self.gwl_tuples.append(
                GwlReading(fields[0], fields[1], fields[2], fields[3], fields[4], fields[5],
                           timestamp, data_value)
            )

        print(self.gwl_tuples)

        while True:
            pass




fetcher = DataFetcher()
fetcher.select_state()



# seems unreliable. You sure we cannot figure out how to press the dang button?
# # now to try and get the readings out of the graph. How?
# # floating graphic xpath
# # this remains the same, it just updates the number every time, as expected
# # the key idea would be to somehow create the hover effect that gives us the number
# floating_xpath = "/html/body/app-root/app-groundwaterlevelnew/div[1]/div[2]/div/div/div[2]/div[4]/div/div[3]/div[3]/span/table/tbody/tr"
# first_bar_xpath = "/html/body/app-root/app-groundwaterlevelnew/div[1]/div[2]/div/div/div[2]/div[4]/div/div[3]/svg/g[2]/path[1]"
# first_bar_selector = "#highcharts-pt563z4-371 > svg > path"
# hover_away_xpath = "/html/body/app-root/app-ground-water/app-header/div[1]/div/div/div[1]/ul/li[3]"
# time.sleep(90) # another slowdown to scraper performance...
# # hover over the first bar to update the span table
# first_bar = WebDriverWait(self.driver, 60).until(
#     EC.presence_of_element_located((By.CSS_SELECTOR, first_bar_selector))
# )
# ActionChains(self.driver).move_to_element(first_bar).perform()
# hover_away = self.driver.find_element(By.XPATH, hover_away_xpath)
# ActionChains(self.driver).move_to_element(hover_away).perform()
#
# # now harvest the month and value
# floating_infographic = self.driver.find_element(By.XPATH, floating_xpath)
# floating_infographic_html = BeautifulSoup(floating_infographic.get_attribute("outerHTML"), 'html.parser')
# print(floating_infographic_html)