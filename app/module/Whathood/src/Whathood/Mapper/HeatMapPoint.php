<?php

namespace Whathood\Mapper;

use Whathood\Entity\Neighborhood;
use Whathood\Entity\HeatMapPoint as HMP;

/**
 * Description of NeighborhoodMapper
 *
 * @author Jim Smiley twitter:@jimRsmiley
 */
class HeatMapPoint extends BaseMapper {

    public function byNeighborhood( Neighborhood $neighborhood ) {

        if( empty( $neighborhood ) )
            throw new \InvalidArgumentException( ' may not be null' );

        $qb = $this->em->createQueryBuilder();
        $qb->select( array( 'hmp') )
                ->from('Whathood\Entity\HeatMapPoint', 'hmp')
                ->where( 'hmp.neighborhood = ?1' )
                ->setParameter(1, $neighborhood->getId() );

        try {
            return $qb->getQuery()->getResult();
        } catch( \Exception $e ) {
            print $e->getMessage();
            exit;
        }
    }

    public function deleteByNeighborhood(Neighborhood $neighborhood) {
        $sql = "DELETE FROM Whathood\Entity\HeatMapPoint hmp WHERE hmp.neighborhood = :neighborhood_id";
        $this->em->createQuery($sql)
            ->setParameter(':neighborhood_id',$neighborhood->getId())
            ->execute();
    }

    public function savePoints(array $heatmap_points) {
        if (empty($heatmap_points))
            throw new \InvalidArgumentException("heatmap_points may not be empty");
        foreach($heatmap_points as $hmp) {
            $this->save($hmp);
        }
    }

    public function save( HMP $heatmap_point ) {
        $this->em->persist( $heatmap_point );
        $this->em->flush( $heatmap_point );
    }

    public function getQueryBuilder() {
        return new \Whathood\Doctrine\ORM\Query\NeighborhoodQueryBuilder(
                $this->em->createQueryBuilder() );
    }
}
?>
