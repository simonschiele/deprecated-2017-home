#!/bin/bash
#
# depends: poppler-utils, xml2
#
# http://isbndb.com/
# http://www.lookupbyisbn.com/
# http://www.isbn.nu/
# http://easybib.com/cite/form/book
# http://search.barnesandnoble.com/booksearch/isbninquiry.asp?ISBN=

ISBNDB_KEY="XXXXXX"

if [ -z "${@}" ]
then
    echo "[error] please give pdf as argument"
    exit 1
fi

if ! [ -e "${@}" ]
then
    echo "[error] file \"${@}\" not found"
    exit 1
fi

pdf="${@}"
if ! ( file "${pdf}" | grep -qi "pdf" )
then
    echo "[error] input file seems not to be pdf"
    exit 1
fi

pages=$( pdfinfo "${pdf}" | grep ^Pages | sed 's|.*\:\ *\(.*\)$|\1|g' )
if [ $pages -lt 11 ]
then
    echo "[error] pdf has less than 11 pages"
    exit 1
fi

search_for_isbns() {
    if [ -z "$@" ]
    then
        echo "[WARNING] empty text passed to 'search_for_isbns()'"
    fi

    ISBNs=$( echo "${@}" | grep -i "ISBN" | grep -o "[0-9\-]\{10,17\}" )
    echo "$ISBNs"
}

isbn2details() {
    URL="http://isbndb.com/api/books.xml?access_key=${ISBNDB_KEY}&amp;index1=isbn&amp;value1=$( echo ${@} | sed 's|\-||g' )"
    wget -q -O- "${URL}" 
}

details2filename() {
    #/ISBNdb/@server_time=2012-08-30T21:44:18Z
    #/ISBNdb/BookList/@total_results=1
    #/ISBNdb/BookList/@page_size=10
    #/ISBNdb/BookList/@page_number=1
    #/ISBNdb/BookList/@shown_results=1
    #/ISBNdb/BookList/BookData/@book_id=head_first_c_a01
    #/ISBNdb/BookList/BookData/@isbn=1449399916
    #/ISBNdb/BookList/BookData/@isbn13=9781449399917
    #/ISBNdb/BookList/BookData/Title=Head First C
    #/ISBNdb/BookList/BookData/TitleLong
    #/ISBNdb/BookList/BookData/AuthorsText=David Griffiths, Dawn Griffiths,
    #/ISBNdb/BookList/BookData/PublisherText/@publisher_id=oreilly_media
    #/ISBNdb/BookList/BookData/PublisherText=O'Reilly Media
    old_filename="${1}"    
    rawdata="${2}"
    
    author=$( echo "${rawdata}" | xml2 | grep "^/ISBNdb/BookList/BookData/AuthorsText=" | cut -d'=' -f'2-' | sed 's|,\ *$||g' )
    title=$( echo "${rawdata}" | xml2 | grep "^/ISBNdb/BookList/BookData/Title=" | cut -d'=' -f'2-' )
    isbn=$( echo "${rawdata}" | xml2 | grep "^/ISBNdb/BookList/BookData/@isbn13=" | cut -d'=' -f'2-' )
    if [ -z ${isbn} ]
    then
        isbn=$( echo "${rawdata}" | xml2 | grep "^/ISBNdb/BookList/BookData/@isbn=" | cut -d'=' -f'2-' )
    fi
    publisher=$( echo "${rawdata}" | xml2 | grep "^/ISBNdb/BookList/BookData/PublisherText=" | cut -d'=' -f'2-' )
    year=$( echo "${publisher}" | grep -o '[1-2]\{1\}[0-9]\{3\}' | tail -n 1 )
    if [ -z "${year}" ]
    then
        year=$( echo "${old_filename}" | grep -o '[1-2]\{1\}[0-9]\{3\}' | tail -n 1 )
    fi
    if [ -n "${year}" ]
    then 
        year=$( echo "${year}" | sed 's|^|,\ |g' )
    fi
    echo "${author} - ${title} (${isbn}${year}).pdf"
}

echo ">>> Converting first 10 Pages of pdf to text"
raw=$( pdftotext -l 10 "${pdf}" - 2>/dev/null )

echo ">>> Searching for ISBNs"
ISBNs=$( search_for_isbns "${raw}" )
ISBNs_count=$( echo "${ISBNs}" | wc -l )
echo "> ${ISBNs_count} ISBNs found"

if [ ${ISBNs_count} -lt 1 ]
then
    echo -n 
elif [ ${ISBNs_count} -lt 2 ]
then
    data=$( isbn2details "${ISBNs}" )
    new_filename=$( details2filename "${pdf}" "${data}" )

    echo "> rename \"${pdf}\" => \"${new_filename}\"? "
    read -e answer
    for continue in y Y yes Yes YES ja j J
    do
        if [ "_${answer}" == "_${continue}" ]
        then
            mv -v "${pdf}" "${new_filename}"
            exit 0
        fi
    done
else
    i=0
    for ISBN in $ISBNs
    do
        i=$(( $i + 1 ))
        data[$i]=$( isbn2details "${ISBN}" )
        new_filename=$( details2filename "${pdf}" "${data[$i]}" )
        
        echo "${i}) ${new_filename}"
    done
    
    echo -n "Please choose the correct book (1-${ISBNs_count}): "
    read -e answer
    
    for i in `seq 1 ${ISBNs_count}`
    do
        if [ "_${answer}" == "_${i}" ]
        then
            new_filename=$( details2filename "${pdf}" "${data[$i]}" )
            
            echo ">>> Renaming \"${pdf}\" => \"${new_filename}\""
            mv "${pdf}" "${new_filename}"
            exit 0
        fi
    done
fi

echo ">>> Converting rest of pdf to text"
raw=$( pdftotext -f 11 "${pdf}" - 2>/dev/null )

echo ">>> Searching for ISBNs"
ISBNs=$( search_for_isbns "${raw}" )
ISBNs_count=$( echo "${ISBNs}" | wc -l )
echo "> ${ISBNs_count} ISBNs found"

if [ ${ISBNs_count} -lt 1 ]
then
    echo -n
elif [ ${ISBNs_count} -lt 2 ]
then
    data=$( isbn2details "${ISBNs}" )
    new_filename=$( details2filename "${pdf}" "${data}" )

    echo "> rename \"${pdf}\" => \"${new_filename}\"? "
    read -e answer
    for continue in y Y yes Yes YES ja j J
    do
        if [ "_${answer}" == "_${continue}" ]
        then
            mv -v "${pdf}" "${new_filename}"
            exit 0
        fi
    done
else
    i=0
    for ISBN in $ISBNs
    do
        i=$(( $i + 1 ))
        data[$i]=$( isbn2details "${ISBN}" )
        new_filename=$( details2filename "${pdf}" "${data[$i]}" )

        echo "${i}) ${new_filename}"
    done

    echo -n "Please choose the correct book (1-${ISBNs_count}): "
    read -e answer

    for i in `seq 1 ${ISBNs_count}`
    do
        if [ "_${answer}" == "_${i}" ]
        then
            new_filename=$( details2filename "${pdf}" "${data[$i]}" )

            echo ">>> Renaming \"${pdf}\" => \"${new_filename}\""
            mv "${pdf}" "${new_filename}"
            exit 0
        fi
    done
fi

