import sys


def main():
    debug('Hello, I am Pythee, I am being pythoned !')
    sys_args = sys.argv
    sys_args.pop(0)
    if sys_args:
        debug(f'sys_args = {sys_args}')


def debug(msg, *args, **kwargs):
    if args:
        msg = f'{msg} {args}'
    print(msg)


if __name__ == '__main__':
    main()
