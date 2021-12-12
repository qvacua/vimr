## How to use

* `cd` into `${PROJECT_ROOT}/bin`, this directory.
* Install pyenv and pyenv-virtuelenv.
* Install Python 3.9.7 using pyenv.
* Create a virtualenv with the name `com.qvacua.VimR.bin`.
* Ensure that you're running the Python in the virtualenv by
    ```bash
    pyenv which python
    /${HOME}/.pyenv/versions/com.qvacua.VimR.bin/bin/python
    ```
* Install the requirements
    ```bash
    pip install -r requirements.txt
    python setup.py develop
    ```

## How to build third party dependencies

* Run `build.py` with, for example, the following arguments
    ```
    $ python build.py --arm64-deployment-target=11.00 --x86_64-deployment-target=10.13 \
                      --xz-version 5.2.4 --pcre-version 8.43 --ag-version 2.2.0
    ```

### Built artifacts

The resulting artifacts are structured as follows

```
./third_party
    vimr-deps
        lib
            liba.a
            libb.a
            ...
        include
            a.h
            b.h
            ...
    liba
        include
            a.h
            ...
    libb
        include
            b.h
            ...
```
