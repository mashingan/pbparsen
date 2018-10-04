#? stdtmpl | standard
#
#import tables, strformat, times
#import sqlgen
#import utils
#
#proc goRepository*(tbl: SqlTable, namesvc, basepath: string, version = ""): string =
#result = ""
/*
Generated with repogen $version (c) Rahmatullah
#var generatedTime = format(now(), "dd-MM-yyyy HH:mm:sszzz")
@ $generatedTime
*/
package repository

import (
        s "strings"

        $namesvc "$basepath"
#var entitypath = basepath & "/entity"
        "$entitypath"

        logging "github.com/go-kit/kit/log"
        level "github.com/go-kit/kit/log/level"
        
        "github.com/jinzhu/gorm"
        _ "github.com/lib/pq"
)

#var tblname = tbl.name.toPascalCase
#var reponame = tblname & "Repository"
#var idtype = tbl.fields["id"].kind.typeMap
#var retname = "*entity." & tblname
#var retnameobj = "entity." & tblname
#var searchpath = fmt"""r.DB.Exec("SET search_path TO {tbl.schema}")"""
#var hasschema = tbl.schema != ""
#var errnotfound = namesvc & ".ErrNotFoundError"
#var errinvalidop = namesvc & ".InvalidSqlOperation"
#var flogerr = ""
type $reponame interface {
        GetById(id $idtype)($retname, error)
        Get$tblname(limit, page int) ([]$retnameobj, error)
        GetWith(fmtval map[string][]interface{}) ([]$retnameobj, error)
        Create$tblname(obj $retnameobj) ($retnameobj, error)
        DeleteById(id $idtype) ($retname, error)
        DeleteWith(fmtval map[string][]interface{}) ([]$retnameobj, error)
        UpdateById(obj $retname, id $idtype) ($retname, error)
}

#var repoimpl = reponame & "Impl"
type $repoimpl struct {
        *gorm.DB
        logger logging.Logger
}

#var instrepo = "New" & repoimpl
func $instrepo(db *gorm.DB, logger logging.Logger) $reponame {
        return &$repoimpl{db, logger}
}

func (r *$repoimpl) GetById(id $idtype)($retname, error) {
        var result entity.$tblname
        #if hasschema:
        $searchpath
        #end if
        if err := r.DB.Where("id = ?", id).First(&result).Error; err != nil {
                #flogerr = funcLogError(repoimpl & " GetById")
                $flogerr
                return nil, $errnotfound
        }
        return &result, nil
}

func (r *$repoimpl) Get$tblname(limit, page int) ([]$retnameobj, error) {
        var result []$retnameobj
        #if hasschema:
        $searchpath
        #end if
        r.DB.Limit(limit).Offset(limit * (page - 1))
        if err := r.DB.Find(&result).Error; err != nil {
                #flogerr = funcLogError(repoimpl & " Get" & tblname)
                $flogerr
                return nil, $errnotfound
        }
        return result, nil
}


func (r *$repoimpl) GetWith(fmtval map[string][]interface{}) ([]$retnameobj, error) {
        var result []$retnameobj
        #if hasschema:
        $searchpath
        #end if
        for key, opval := range fmtval {
                op := string(opval[0])
                val := opval[1]
                switch s.ToLower(op) {
                case "and":
                        r.DB.where(key, val)
                case "or":
                        r.DB.Or(key, val)
                default:
                      #flogerr = funcLogError(repoimpl & " GetWith", errinvalidop)
                      $flogerr
                      return nil, $errinvalidop
                }
        }
        if err := r.DB.Find(&result).Error; err != nil {
                #flogerr = funcLogError(repoimpl & " GetWith")
                $flogerr
                return nil, err
        }
        return result, nil
}

func (r *$repoimpl) Create$tblname(obj $retname) ($retname, error) {
        #if hasschema:
        $searchpath
        #end if
        if err := r.DB.Create(obj).Error; err != nil {
                #flogerr = funcLogError(repoimpl & " Create" & tblname)
                $flogerr
                return nil, err
        }
        return obj, nil
}

func (r *$repoimpl) DeleteById(id $idtype) ($retname, error) {
        var result $retnameobj
        #if hasschema:
        $searchpath
        #end if
        var err error
        if err = r.DB.Where("id =?", id).Find(&result).Error; err != nil {
                #flogerr = funcLogError(repoimpl & " DeleteById")
                $flogerr
                return nil, $errnotfound
        }
        if err = r.DB.Delete(&result).Error; err != nil {
                #flogerr = funcLogError(repoimpl & " DeleteById")
                $flogerr
                return nil, err
        }
        return &result, nil
}

func (r *$repoimpl) DeleteWith(fmtval map[string][]interface{}) ([]$retnameobj, error) {
        var result []$retnameobj
        #if hasschema:
        $searchpath
        #end if
        for key, opval := range fmtval {
                op := string(opval[0])
                val := opval[1]
                switch s.ToLower(op) {
                case "and":
                        r.DB.Where(key, val)
                case "or":
                        r.DB.Or(key, val)
                default:
                        #flogerr = funcLogError(repoimpl & " DeleteWith", errinvalidop)
                        $flogerr
                        return nil, $errinvalidop

                }
        }
        if err := r.DB.Find(&result).Error(); err != nil {
                #flogerr = funcLogError(repoimpl & " DeleteWith")
                $flogerr
                return nil, $errnotfound
        }
        if err := r.DB.Delete(&result).Error(); err != nil {
                #flogerr = funcLogError(repoimpl & " DeleteWith")
                $flogerr
                return nil, err
        }
        return result, nil
}

func (r *$repoimpl) UpdateById(obj $retname, id $idtype) ($retname, error) {
        var result $retnameobj
        #if hasschema:
        $searchpath
        #end if
        var err error
        if err  = r.DB.Where("id = ?", id).Find(&result).Error; err != nil {
                  #flogerr = funcLogError(repoimpl & " UpdateById")
                  $flogerr
                  return nil, $errnotfound
        }
        result = *obj
        if err = r.DB.Save(&result).Error; err != nil {
                #flogerr  = funcLogError(repoimpl & " UpdateById")
                $flogerr
                return nil, err
        }
        return &result, nil
}
