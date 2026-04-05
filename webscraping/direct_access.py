import time
import requests
import csv
from dataclasses import dataclass, fields, asdict
import pandas as pd
# exposed db endpoint. Fuck it.

@dataclass(frozen=True)
class GwlReading:
    station_name: str
    station_code: str
    state: str
    district: str
    basin: str
    sub_basin: str
    timestamp: str
    reading: str


class DirectAccess:
    headers = {'Accept': 'application/json, text/plain, */*',
               'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
               'Access-Control-Allow-Methods': 'GET,POST',
               'Access-Control-Allow-Origin': '*',
               'Cache-Control': 'no-cache',
               'Connection': 'keep-alive',
               'Content-Type': 'application/json',
               'Origin': 'https://indiawris.gov.in',
               'Pragma': 'no-cache',
               'Referer': 'https://indiawris.gov.in/wdo/',
               'Sec-Fetch-Dest': 'empty',
               'Sec-Fetch-Mode': 'cors',
               'Sec-Fetch-Site': 'same-origin',
               'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
               'sec-ch-ua': '"Chromium";v="146", "Not-A.Brand";v="24", "Google Chrome";v="146"',
               'sec-ch-ua-mobile': '?0',
               'sec-ch-ua-platform': 'macOS',
               }
    agency_tuples = list()

    def fetch_agency_data(self, agency):
        self.fetch_states(agency)
        self.write_output_to_csv(agency)

    def fetch_agency_list(self):
        headers = {'Accept': '*/*',
                   'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
                   'Access-Control-Allow-Methods': 'GET,POST',
                   'Access-Control-Allow-Origin': '*',
                   'Connection': 'keep-alive',
                   'Content-Type': 'application/json',
                   'Origin': 'https://indiawris.gov.in',
                   'Referer': 'https://indiawris.gov.in/wdo/',
                   'Sec-Fetch-Dest': 'empty',
                   'Sec-Fetch-Mode': 'cors',
                   'Sec-Fetch-Site': 'same-origin',
                   'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
                   'sec-ch-ua': '"Chromium";v="146", "Not-A.Brand";v="24", "Google Chrome";v="146"',
                   'sec-ch-ua-mobile': '?0',
                   'sec-ch-ua-platform': '"macOS"'
                   }
        url = 'https://indiawris.gov.in/gwlAgencyName'
        data = '{"stnVal":{"qry":"select distinct agency_name from gwl_agency_minmax_date"}}'
        response = requests.post(
            url,
            timeout=600,
            headers=headers,
            data=data
        )
        agency_list = response.json()
        agency_list = [agency for agency_inner_list in agency_list for agency in agency_inner_list]
        for agency in agency_list:
            print(agency)
            self.fetch_states(agency)
            self.write_output_to_csv(agency)
            break

    def fetch_states(self, agency):
        url = 'https://indiawris.gov.in/gwlbusinessdata'
        data = f'{{"stnVal":{{"qry":"\\n                    SELECT metadata.state_name, COUNT(DISTINCT(metadata.station_code)), \\n                           COALESCE(ROUND(MIN(businessdata.level)::NUMERIC, 2), 0) AS minlevel,\\n                           COALESCE(ROUND(MAX(businessdata.level)::NUMERIC, 2), 0) AS maxlevel \\n                    FROM public.groundwater_station AS metadata \\n                    INNER JOIN public.gwl_timeseries_data AS businessdata \\n                    ON metadata.station_code = businessdata.station_code \\n                    WHERE 1=1  and metadata.agency_name = \'{agency}\' and  businessdata.date between \'1993-12-01\' and \'2025-10-01\'  \\n                    GROUP BY metadata.state_name \\n                    ORDER BY metadata.state_name"}}}}'
        response = requests.post(
            url,
            timeout=600,
            headers=self.headers,
            data=data
        )
        state_list = response.json()
        state_list = [state_tuple[0] for state_tuple in state_list]


        # restarts
        cgwb = pd.read_csv("CGWB_accumulator.csv")
        # find the state to start from
        done_states = cgwb['state'].unique()
        done_states = done_states.tolist()
        done_states.pop()
        print(done_states)
        print(state_list)
        for done_state in done_states:
            state_list.remove(done_state)

        print(state_list)
        for state in state_list:
            self.fetch_districts(state, agency)

    def fetch_districts(self, state, agency):
        url = 'https://indiawris.gov.in/gwlbusinessdata'
        data = f'{{"stnVal":{{"qry":"select metadata.district_name,count(distinct(businessdata.station_code)), coalesce(ROUND(min(businessdata.level)::numeric,2), 0) as minlevel,coalesce(ROUND(max(businessdata.level)::numeric,2), 0) as maxlevel from public.groundwater_station as metadata INNER JOIN public.gwl_timeseries_data as businessdata on metadata.station_code = businessdata.station_code where 1=1  and metadata.agency_name = \'{agency}\' and metadata.state_name = \'{state}\' and  businessdata.date between \'1993-12-01\' and \'2025-10-01\'  group by district_name"}}}}'
        response = requests.post(
            url,
            timeout=600,
            headers=self.headers,
            data=data
        )
        district_list = response.json()
        district_list = [district_tuple[0] for district_tuple in district_list]

        # restarts
        cgwb = pd.read_csv("CGWB_accumulator.csv")
        done_districts = cgwb[cgwb['state'] == state]
        done_districts = done_districts['district'].unique()
        done_districts = done_districts.tolist()
        # have to cover for fresh starts, not just restarts smh
        if len(done_districts) != 0:
            done_districts.pop()
            for done_district in done_districts:
                district_list.remove(done_district)

        print(district_list)
        for district in district_list:
            self.fetch_stations(district, state, agency)


    def fetch_stations(self, district, state, agency):
        url = 'https://indiawris.gov.in/gwlbusinessdata'
        data = f'{{"stnVal":{{"qry":"select metadata.station_name, metadata.station_code,coalesce(ROUND(min(businessdata.level)::numeric,2), 0) as minlevel,coalesce(ROUND(max(businessdata.level)::numeric,2), 0) as maxlevel from public.groundwater_station as metadata INNER JOIN public.gwl_timeseries_data as businessdata on metadata.station_code = businessdata.station_code where 1=1  and metadata.agency_name = \'{agency}\' and metadata.state_name = \'{state}\' and lower(metadata.district_name) = lower(\'{district}\') and  businessdata.date between \'1993-12-01\' and \'2025-10-01\'  group by metadata.station_name, metadata.station_code"}}}}'
        response = requests.post(
            url,
            timeout=600,
            headers=self.headers,
            data=data
        )
        station_list = response.json()
        station_list = [(station_tuple[0], station_tuple[1]) for station_tuple in station_list]

        # restarts
        cgwb = pd.read_csv("CGWB_accumulator.csv")
        done_stations = cgwb[(cgwb['state'] == state) & (cgwb['district'] == district)]
        done_stations = done_stations['station_name'].unique()
        done_stations = done_stations.tolist()



        station_list = list(filter(lambda x: x[0] not in done_stations, station_list))
        # for done_station in done_stations:
        #     station_list.remove(done_station)

        print(station_list)
        for station in station_list:
            self.fetch_station_data(station[0], station[1], district, state, agency)


    def fetch_station_metadata(self, station_code):
        url = 'https://indiawris.gov.in/gwlbusinessdata'
        data = f'{{"stnVal":{{"qry":"select metadata.station_name, metadata.station_code, metadata.state_name, metadata.district_name, metadata.basin_name, metadata.sub_basin_name, ROUND(min(businessdata.level):: numeric, 2) as minlevel, ROUND(max(businessdata.level):: numeric, 2) as maxlevel FROM public.groundwater_station as metadata INNER JOIN public.gwl_timeseries_data as businessdata on metadata.station_code = businessdata.station_code where metadata.station_code = \'{station_code}\' and to_char(date, \'yyyy-mm-dd\') between \'1993-12-01\' and \'2025-10-01\' group by metadata.station_name, metadata.station_code,metadata.state_name, metadata.district_name, metadata.basin_name, metadata.sub_basin_name"}}}}'
        response = requests.post(
            url,
            timeout=600,
            headers=self.headers,
            data=data
        )
        metadata = response.json()
        metadata = [item for row in metadata for item in row]
        return metadata


    def fetch_station_data(self, station, station_code, district, state, agency):
        metadata_response = self.fetch_station_metadata(station_code)
        print(metadata_response)

        url = 'https://indiawris.gov.in/gwltimeseriesdata'
        start_date = '1994-01'
        end_date = '2025-09'

        data = f'{{"stnVal":{{"qry":"select TRIM(to_char(businessdata.date, \'yyyy-Mon\')) as month, \\n\\t\\t\\t\\t\\t\\t   ROUND(AVG(businessdata.level)::numeric, 2) as level, \\n\\t\\t\\t\\t\\t\\t   to_char(businessdata.date, \'yyyy\') as yy, \\n\\t\\t\\t\\t\\t\\t   to_char(businessdata.date, \'mm\') as mm \\n\\t\\t\\t\\t\\tFROM public.gwl_timeseries_data as businessdata \\n\\t\\t\\t\\t\\tINNER JOIN public.groundwater_station as metadata \\n\\t\\t\\t\\t\\tON metadata.station_code = businessdata.station_code \\n\\t\\t\\t\\t\\tWHERE 1=1  and metadata.agency_name = \'{agency}\' and metadata.state_name = \'{state}\' and lower(metadata.district_name) = lower(\'{district}\') and lower(metadata.station_name) = lower(\'{station}\')  \\n\\t\\t\\t\\t\\tAND to_char(businessdata.date, \'yyyy-mm\') between \'{start_date}\' and \'{end_date}\' \\n\\t\\t\\t\\t\\tGROUP BY month, yy, mm \\n\\t\\t\\t\\t\\tORDER BY yy, mm"}}}}'
        response = requests.post(
            url,
            timeout=600,
            headers=self.headers,
            data=data
        )

        basin = ''
        sub_basin = ''
        if len(metadata_response) != 0:
            basin = metadata_response[4]
            sub_basin = metadata_response[5]

        try:
            for timestamp, reading, _, __ in response.json():
                row = GwlReading(
                    station_name=station,
                    station_code=station_code,
                    state=state,
                    district=district,
                    basin=basin,
                    sub_basin=sub_basin,
                    timestamp=timestamp,
                    reading=reading,
                )
                self.agency_tuples.append(row)
        except requests.exceptions.JSONDecodeError as e:
            print(f"Whoops! JSON problems in {state}, {district}, {station}!")
            return

    def write_output_to_csv(self, agency):
        with open(f"{''.join(agency.split())}_accumulator.csv", "a", newline='\n') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=[f.name for f in fields(GwlReading)])
            # writer.writeheader()
            writer.writerows([asdict(row) for row in self.agency_tuples])
        self.agency_tuples.clear()


def collector():
    try:
        direct_access = DirectAccess()
        direct_access.fetch_agency_data('CGWB')
    except Exception as e:
        print(e)
        print("Server is messed up. Retrying in 10 minutes.")
        direct_access.write_output_to_csv('CGWB')
        time.sleep(600)
        collector()

collector()