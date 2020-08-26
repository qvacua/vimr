## How to use

* `cd` into `${PROJECT_ROOT}/third-party`, this directory.
* Install pyenv and pyenv-virtuelenv.
* Install Python 3.8.x using pyenv.
* Create a virtualenv with the name `com.qvacua.VimR.third-party`.
* Ensure that you're running the Python in the virtualenv by
    ```
    $ pyenv which python
    /${HOME}/.pyenv/versions/com.qvacua.VimR.third-party/bin/python
    ```
* Install the requirements
    ```
    $ pip install -r requirements.txt
    ```
* Do the following
    ```
    $ python setup.py develop
    ```
* Run `build.py` with, for example, the following arguments
    ```
    $ python build.py --arm64-deployment-target=11.00 --x86_64-deployment-target=10.13 \
                      --xz-version 5.2.4 --pcre-version 8.43 --ag-version 2.2.0
    ```

## Built artifacts

The resulting artifacts are structured as follows

```
third-party
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

## IntelliJ settings

* Open /third-party, this directory.
* Add the virtualenv `com.qvacua.VimR.third-party` as Python SDK.
* Set the project SDK to the virtualenv.
* Set the content root to Sources
* Optional: Set all install paths, i.e. `vimr-deps` and `lib*/`, to Excluded.