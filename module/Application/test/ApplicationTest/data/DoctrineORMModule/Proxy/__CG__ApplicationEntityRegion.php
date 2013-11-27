<?php

namespace DoctrineORMModule\Proxy\__CG__\Application\Entity;

/**
 * THIS CLASS WAS GENERATED BY THE DOCTRINE ORM. DO NOT EDIT THIS FILE.
 */
class Region extends \Application\Entity\Region implements \Doctrine\ORM\Proxy\Proxy
{
    private $_entityPersister;
    private $_identifier;
    public $__isInitialized__ = false;
    public function __construct($entityPersister, $identifier)
    {
        $this->_entityPersister = $entityPersister;
        $this->_identifier = $identifier;
    }
    /** @private */
    public function __load()
    {
        if (!$this->__isInitialized__ && $this->_entityPersister) {
            $this->__isInitialized__ = true;

            if (method_exists($this, "__wakeup")) {
                // call this after __isInitialized__to avoid infinite recursion
                // but before loading to emulate what ClassMetadata::newInstance()
                // provides.
                $this->__wakeup();
            }

            if ($this->_entityPersister->load($this->_identifier, $this) === null) {
                throw new \Doctrine\ORM\EntityNotFoundException();
            }
            unset($this->_entityPersister, $this->_identifier);
        }
    }

    /** @private */
    public function __isInitialized()
    {
        return $this->__isInitialized__;
    }

    
    public function getId()
    {
        if ($this->__isInitialized__ === false) {
            return (int) $this->_identifier["id"];
        }
        $this->__load();
        return parent::getId();
    }

    public function setId($id)
    {
        $this->__load();
        return parent::setId($id);
    }

    public function getName()
    {
        $this->__load();
        return parent::getName();
    }

    public function setName($name)
    {
        $this->__load();
        return parent::setName($name);
    }

    public function getCenterPoint()
    {
        $this->__load();
        return parent::getCenterPoint();
    }

    public function setCenterPoint($centerPoint)
    {
        $this->__load();
        return parent::setCenterPoint($centerPoint);
    }

    public function getBorderPolygon()
    {
        $this->__load();
        return parent::getBorderPolygon();
    }

    public function setBorderPolygon($data)
    {
        $this->__load();
        return parent::setBorderPolygon($data);
    }

    public function setNeighborhoodPolygons(\Doctrine\Common\Collections\ArrayCollection $arrayCollection)
    {
        $this->__load();
        return parent::setNeighborhoodPolygons($arrayCollection);
    }

    public function getNeighborhoodPolygons()
    {
        $this->__load();
        return parent::getNeighborhoodPolygons();
    }

    public function toArray()
    {
        $this->__load();
        return parent::toArray();
    }

    public function offsetExists($index)
    {
        $this->__load();
        return parent::offsetExists($index);
    }

    public function offsetGet($index)
    {
        $this->__load();
        return parent::offsetGet($index);
    }

    public function offsetSet($index, $newval)
    {
        $this->__load();
        return parent::offsetSet($index, $newval);
    }

    public function offsetUnset($index)
    {
        $this->__load();
        return parent::offsetUnset($index);
    }

    public function append($value)
    {
        $this->__load();
        return parent::append($value);
    }

    public function getArrayCopy()
    {
        $this->__load();
        return parent::getArrayCopy();
    }

    public function count()
    {
        $this->__load();
        return parent::count();
    }

    public function getFlags()
    {
        $this->__load();
        return parent::getFlags();
    }

    public function setFlags($flags)
    {
        $this->__load();
        return parent::setFlags($flags);
    }

    public function asort()
    {
        $this->__load();
        return parent::asort();
    }

    public function ksort()
    {
        $this->__load();
        return parent::ksort();
    }

    public function uasort($cmp_function)
    {
        $this->__load();
        return parent::uasort($cmp_function);
    }

    public function uksort($cmp_function)
    {
        $this->__load();
        return parent::uksort($cmp_function);
    }

    public function natsort()
    {
        $this->__load();
        return parent::natsort();
    }

    public function natcasesort()
    {
        $this->__load();
        return parent::natcasesort();
    }

    public function unserialize($serialized)
    {
        $this->__load();
        return parent::unserialize($serialized);
    }

    public function serialize()
    {
        $this->__load();
        return parent::serialize();
    }

    public function getIterator()
    {
        $this->__load();
        return parent::getIterator();
    }

    public function exchangeArray($array)
    {
        $this->__load();
        return parent::exchangeArray($array);
    }

    public function setIteratorClass($iteratorClass)
    {
        $this->__load();
        return parent::setIteratorClass($iteratorClass);
    }

    public function getIteratorClass()
    {
        $this->__load();
        return parent::getIteratorClass();
    }


    public function __sleep()
    {
        return array('__isInitialized__', 'id', 'name', 'centerPoint', 'borderPolygon', 'neighborhoodPolygons');
    }

    public function __clone()
    {
        if (!$this->__isInitialized__ && $this->_entityPersister) {
            $this->__isInitialized__ = true;
            $class = $this->_entityPersister->getClassMetadata();
            $original = $this->_entityPersister->load($this->_identifier);
            if ($original === null) {
                throw new \Doctrine\ORM\EntityNotFoundException();
            }
            foreach ($class->reflFields as $field => $reflProperty) {
                $reflProperty->setValue($this, $reflProperty->getValue($original));
            }
            unset($this->_entityPersister, $this->_identifier);
        }
        
    }
}