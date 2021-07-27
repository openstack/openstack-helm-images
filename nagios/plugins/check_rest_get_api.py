#!/usr/bin/env python
# -*- encoding: utf-8 -*-
#
# REST API monitoring script for Nagios
#
# Authors:
#   Rakesh Patnaik <rp196m@att.com>
# Updated:
#   Radhika Pai <rp592h@att.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Requirments: python-argparse, python-requests

import sys
import argparse
import requests
import warnings
from urllib.parse import urlparse
warnings.filterwarnings("ignore")

STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2
STATE_UNKNOWN = 3


def main():
    parser = argparse.ArgumentParser(description='Check REST API status.')
    parser.add_argument('--url', metavar='URL', type=str,
                        required=True,
                        help='REST URL')
    parser.add_argument(
        '--expected_response_code',
        metavar='expected_response_code',
        type=int,
        required=False,
        help='Expected Response Code')
    parser.add_argument(
        '--expected_response_codes',
        metavar='expected_response_codes',
        type=str,
        required=False,
        help='Comma separated Expected Response Codes')
    parser.add_argument(
        '--warning_response_seconds',
        metavar='warning_response_seconds',
        type=str,
        required=False,
        help='Number of seconds for response past which raise a warning alert')
    parser.add_argument(
        '--critical_response_seconds',
        metavar='critical_response_seconds',
        type=str,
        required=False,
        help='Number of seconds for response past which raise a critical alert')
    parser.add_argument('--https_proxy', metavar='https_proxy', type=str,
                        required=False,
                        help='Name of the https proxy.')
    parser.add_argument('--http_proxy', metavar='http_proxy', type=str,
                        required=False,
                        help='Name of the http proxy.')

    args = parser.parse_args()

    timeout_seconds = 10
    warning_seconds = timeout_seconds
    critical_seconds = timeout_seconds
    max_retry = 5

    if args.warning_response_seconds:
        warning_seconds = int(args.warning_response_seconds)

    if args.critical_response_seconds:
        critical_seconds = int(args.critical_response_seconds)

    expected_response_codes = []
    if args.expected_response_code:
        if args.expected_response_code not in expected_response_codes:
            expected_response_codes.append(args.expected_response_code)

    if args.expected_response_codes:
        for expected_response_code in args.expected_response_codes.split(','):
            required_response_code = int(expected_response_code)
            if required_response_code not in expected_response_codes:
                expected_response_codes.append(required_response_code)

    if len(expected_response_codes) < 1:
        expected_response_codes.append(200)

    proxies = {
        "http": "",
        "https": ""
    }
    if args.http_proxy:
        proxies["http"] = args.http_proxy
    if args.https_proxy:
        proxies["https"] = args.https_proxy

    parsed = urlparse(args.url)
    replaced = parsed._replace(
        netloc="{}:{}@{}".format(parsed.username, "???", parsed.hostname))
    screened_url = replaced.geturl()

    retry = 1

    while retry < max_retry:
        try:
            response = requests.get(
                include_schema(
                    args.url),
                proxies=proxies,
                timeout=timeout_seconds,
                verify=False)  # nosec

            response_seconds = response.elapsed.total_seconds()
            response_time = "[RT={:.4f}]".format(response_seconds)

            if response_seconds >= warning_seconds and response_seconds < critical_seconds:
                print("WARNING: using URL {} response seconds {} is more than warning threshold {} seconds. {}".format(
                    screened_url, response_seconds, warning_seconds, response_time))
                sys.exit(STATE_WARNING)

            if response.status_code not in expected_response_codes:
                print("CRITICAL: using URL {} expected HTTP status codes {} but got {}. {}".format(
                    screened_url, expected_response_codes, response.status_code, response_time))
                sys.exit(STATE_CRITICAL)

            if response_seconds >= critical_seconds:
                print("CRITICAL: using URL {} response seconds {} is more than critical threshold {} seconds. {}".format(
                    screened_url, response_seconds, critical_seconds, response_time))
                sys.exit(STATE_CRITICAL)

            print("OK: URL {} returned response code {}. {}".format(
                screened_url, response.status_code, response_time))
            sys.exit(STATE_OK)

        except requests.exceptions.Timeout:
            if retry < max_retry:
                print('Request timeout, Retrying - {}'.format(retry))
                retry += 1
                continue
            else:
                print("CRITICAL: Timeout in {} seconds to fetch from URL {}".format(
                    timeout_seconds, screened_url))
                sys.exit(STATE_CRITICAL)
        except Exception as e:
            print("CRITICAL: Failed to fetch from URL {} with reason {}".format(
                screened_url, e))
            sys.exit(STATE_CRITICAL)

        sys.exit(STATE_OK)


def include_schema(api):
    if api.startswith(
            "http://") or api.startswith("https://"):
        return api
    else:
        return "http://{}".format(api)


if __name__ == '__main__':
    sys.exit(main())
