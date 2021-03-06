<?php

namespace Whathood\Entity;

// need this even though Netbeans says you don't
use Doctrine\ORM\Mapping as ORM;
use Zend\Stdlib\Hydrator\ClassMethods as ClassMethodHydrator;
use Doctrine\Common\Collections\ArrayCollection;
/**
 * @ORM\Entity
 * @ORM\Table(name="neighborhood",uniqueConstraints={
 *              @ORM\UniqueConstraint(name="name_region_idx",
 *                  columns={"name","region_id"})})
 */
class Neighborhood extends \ArrayObject {

    /**
     * @ORM\Id
     * @ORM\Column(type="integer")
     * @ORM\GeneratedValue(strategy="AUTO")
     */
    protected $id = null;

    /**
     * @ORM\Column(name="name")
     */
    protected $name = null;

    /**
     * @ORM\Column(name="no_build_border",type="boolean",nullable=true)
     */
    protected $no_build_border;

    /**
     * @ORM\ManyToOne(targetEntity="Whathood\Entity\Region",cascade="persist")
     * @ORM\JoinColumn(name="region_id", referencedColumnName="id",nullable=false)
     */
    protected $region = null;

    /**
     * @ORM\Column(name="date_time_added",type="string")
     */
    protected $dateTimeAdded = null;

    /**
     * @ORM\OneToMany(targetEntity="UserPolygon",
     *                              mappedBy="neighborhood",cascade="persist")
     */
    protected $userPolygons = null;

    /**
     * @ORM\OneToMany(targetEntity="NeighborhoodBoundary",
     *                              mappedBy="neighborhood",cascade="persist")
     */
    protected $neighborhoodPolygons = null;

    public function __construct( $array = null ) {

        if( $array !== null ) {
            $hydrator = new ClassMethodHydrator();
            $hydrator->hydrate( $array, $this );
        }
    }

    public function getId() {
        return $this->id;
    }

    public function setId( $id ) {
        $this->id = $id;
    }

    public function getName() {
        return $this->name;
    }

    public function setName( $name ) {
        $name = ucwords(strtolower($name));
        $this->name = $name;
    }

    public function getRegion() {
        return $this->region;
    }

    public function setRegion( $data ) {
        if( is_array($data) )
            $this->region = new Region($data);
        else if( $data instanceof Region )
            $this->region = $data;
        else
            throw new \InvalidArgumentException(
                                    'data must be array or Region object' );
    }

    public function getDateTimeAdded() {
        return $this->dateTimeAdded;
    }

    public function setDateTimeAdded($dateTimeAdded) {
        $this->dateTimeAdded = $dateTimeAdded;
    }

    public function setUserPolygons( ArrayCollection $arrayCollection ) {
        $this->userPolygons = $arrayCollection;
    }

    public function getUserPolygons() {
        return $this->userPolygons;
    }

    // sugar
    public function noBuildBorder() {
        return $this->getNoBuildBorder();
    }

    public function getNoBuildBorder() {
        return $this->no_build_border;
    }

    public function setNoBuildBorder($no_build_border) {
        $this->no_build_border = $no_build_border;
    }

    public function toArray(array $opts = null) {
        if ($opts == null)
            $opts = array();

        $n_arr = array(
            'id'                => $this->getId(),
            'name'              => $this->getName(),
            'date_time_added'   => $this->getDateTimeAdded(),
            'region_id'         => $this->getRegion()->getId()
        );

        if( $this->getRegion() != null ) {
            $n_arr['region'] = $this->getRegion()->toArray();
        }

        return $n_arr;
    }

    /*
     * utility function that given an array of neighborhoods, returns a json
     * array
     */
    public static function asdfneighborhoodsToJson( $neighborhoodArray ) {

        $jsonArray = array();
        foreach( $neighborhoodArray as $n )
            $jsonArray['neighborhoods'][] = $n->toArray();

        return  \Zend\Json\Json::encode($jsonArray);
    }

    /*
     * utility function that given an array of neighborhoods, returns a json
     * array
     */
    public static function asdfjsonToNeighborhoods( $json ) {

        $array = \Zend\Json\Json::decode( $json, \Zend\Json\Json::TYPE_ARRAY );

        $neighborhoods = array();
        foreach( $array['neighborhoods'] as $neighborhoodArray ) {
            $neighborhoods[] = new Neighborhood( $neighborhoodArray );
        }
        return $neighborhoods;
    }
}
?>
