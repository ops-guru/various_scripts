#!/usr/bin/env python

import feedparser
import argparse
import sys

RELEASE_RSS_MAP = dict(
    stable='https://jenkins.io/changelog-stable/rss.xml',
    weekly='https://jenkins.io/changelog/rss.xml'
)
DEFAULT_RELEASE_CHANNEL = 'stable'


def get_jenkins_latest_version(channel=None, urls_map=RELEASE_RSS_MAP):
    if channel is None:
        channel = DEFAULT_RELEASE_CHANNEL
    feed = feedparser.parse(urls_map.get(channel))
    return feed.entries[0].title.split(' ')[1]


def parse_args(args=None):

    parser = argparse.ArgumentParser(
        description='gets the latest Jenkins official version'
    )
    parser.add_argument(
        '-c', '--channel',
        default=DEFAULT_RELEASE_CHANNEL,
        help='release channel (allowed: [{channels}])'.format(
            channels=RELEASE_RSS_MAP.keys()
        )
    )
    if args is None:
        args = sys.argv[1:]
    return parser.parse_args(args=args)


def main():
    args = parse_args(args=sys.argv[1:])
    version = str(get_jenkins_latest_version(args.channel))
    print(version)
    return 0


if __name__ == '__main__':
    sys.exit(main())
